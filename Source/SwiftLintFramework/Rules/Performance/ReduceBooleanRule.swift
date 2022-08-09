import SourceKittenFramework

public struct ReduceBooleanRule: Rule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "reduce_boolean",
        name: "Reduce Boolean",
        description: "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`",
        kind: .performance,
        nonTriggeringExamples: [
            Example("nums.reduce(0) { $0.0 + $0.1 }"),
            Example("nums.reduce(0.0) { $0.0 + $0.1 }")
        ],
        triggeringExamples: [
            Example("let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }"),
            Example("let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }"),
            Example("let allValid = validators.↓reduce(true) { $0 && $1(input) }"),
            Example("let anyValid = validators.↓reduce(false) { $0 || $1(input) }"),
            Example("let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })"),
            Example("let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })"),
            Example("let allValid = validators.↓reduce(true, { $0 && $1(input) })"),
            Example("let anyValid = validators.↓reduce(false, { $0 || $1(input) })")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "\\breduce\\((true|false)"
        return file
            .match(pattern: pattern, with: [.identifier, .keyword])
            .map { range in
                let reason: String
                if file.contents[Range(range, in: file.contents)!].contains("true") {
                    reason = "Use `allSatisfy` instead"
                } else {
                    reason = "Use `contains` instead"
                }

                return StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: range.location),
                    reason: reason
                )
            }
    }
}
