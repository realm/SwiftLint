import SourceKittenFramework

public struct EmptyCountRule: ConfigurationProviderRule, OptInRule {
    public var configuration = EmptyCountConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_count",
        name: "Empty Count",
        description: "Prefer checking `isEmpty` over comparing `count` to zero.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("var count = 0\n"),
            Example("[Int]().isEmpty\n"),
            Example("[Int]().count > 1\n"),
            Example("[Int]().count == 1\n"),
            Example("[Int]().count == 0xff\n"),
            Example("[Int]().count == 0b01\n"),
            Example("[Int]().count == 0o07\n"),
            Example("discount == 0\n"),
            Example("order.discount == 0\n")
        ],
        triggeringExamples: [
            Example("[Int]().↓count == 0\n"),
            Example("[Int]().↓count > 0\n"),
            Example("[Int]().↓count != 0\n"),
            Example("[Int]().↓count == 0x0\n"),
            Example("[Int]().↓count == 0x00_00\n"),
            Example("[Int]().↓count == 0b00\n"),
            Example("[Int]().↓count == 0o00\n"),
            Example("↓count == 0\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let defaultPattern = #"\bcount\s*(==|!=|<|<=|>|>=)\s*0(\b|([box][0_]+\b){1})"#
        let prefixPattern = configuration.onlyAfterDot ? #"\."# : ""
        let pattern = prefixPattern + defaultPattern

        // Offset the violation location in case `only_after_dot` is turned on,
        // to compensate for the pattern matching the dot
        let offset = configuration.onlyAfterDot ? 1 : 0

        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: $0.location + offset))
        }
    }
}
