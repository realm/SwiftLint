import SourceKittenFramework

public struct ReduceBooleanRule: Rule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "reduce_boolean",
        name: "Prefer allSatisfy or contains over reduce(true) or reduce(false)",
        description: "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`",
        kind: .performance,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            "nums.reduce(0) { $0.0 + $0.1 }",
            "nums.reduce(0.0) { $0.0 + $0.1 }"
        ],
        triggeringExamples: [
            "let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }", // should use allSatisfy instead
            "let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }", // should use contains instead
            "let allValid = validators.↓reduce(true) { $0 && $1(input) }", // should use allSatisfy instead
            "let anyValid = validators.↓reduce(false) { $0 || $1(input) }", // should use contains instead
            "let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })", // should use allSatisfy instead
            "let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })", // should use contains instead
            "let allValid = validators.↓reduce(true, { $0 && $1(input) })", // should use allSatisfy instead
            "let anyValid = validators.↓reduce(false, { $0 || $1(input) })" // should use contains instead
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\breduce\\((true|false)"
        return file
            .match(pattern: pattern,
                   excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
            .compactMap { range in
                let reason = ""

                return StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: range.location),
                    reason: reason
                )
            }
    }
}
