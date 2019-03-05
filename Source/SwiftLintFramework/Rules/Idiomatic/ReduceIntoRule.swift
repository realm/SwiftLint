import SourceKittenFramework

public struct ReduceIntoRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "reduce_into",
        name: "Reduce Into",
        description: "Prefer `reduce(into:_:)` over `reduce(_:_:)`",
        kind: .performance,
        minSwiftVersion: .three,
        nonTriggeringExamples: [
            "let matches = lines.reduce(into: []) { matches, line in",
            "zip(group, group.dropFirst()).reduce(into: []) { result, pair in",
            "values.reduce(into: \"\") { $0.append(\"\\($1)\") }"
        ],
        triggeringExamples: [
            "let matches = lines.↓reduce([]) { matches, line in",
            "zip(group, group.dropFirst()).↓reduce([]) { result, pair in",
            "values.↓reduce(\"\") { $0 + \"\\($1)\" }"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "reduce\\((?!into:)"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
