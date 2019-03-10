import SourceKittenFramework

public struct ReduceBooleanRule: Rule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "reduce_boolean",
        name: "Reduce Boolean",
        description: "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`",
        kind: .performance,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            "nums.reduce(0) { $0.0 + $0.1 }",
            "nums.reduce(0.0) { $0.0 + $0.1 }"
        ],
        triggeringExamples: [
            "let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }",
            "let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }",
            "let allValid = validators.↓reduce(true) { $0 && $1(input) }",
            "let anyValid = validators.↓reduce(false) { $0 || $1(input) }",
            "let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })",
            "let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })",
            "let allValid = validators.↓reduce(true, { $0 && $1(input) })",
            "let anyValid = validators.↓reduce(false, { $0 || $1(input) })"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
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
                    ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: range.location),
                    reason: reason
                )
            }
    }
}
