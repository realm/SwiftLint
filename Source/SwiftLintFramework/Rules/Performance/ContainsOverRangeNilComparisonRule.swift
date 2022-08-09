import SourceKittenFramework

public struct ContainsOverRangeNilComparisonRule: CallPairRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "contains_over_range_nil_comparison",
        name: "Contains over range(of:) comparison to nil",
        description: "Prefer `contains` over `range(of:) != nil` and `range(of:) == nil`.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("let range = myString.range(of: \"Test\")"),
            Example("myString.contains(\"Test\")"),
            Example("!myString.contains(\"Test\")"),
            Example("resourceString.range(of: rule.regex, options: .regularExpression) != nil")
        ],
        triggeringExamples: ["!=", "=="].flatMap { comparison in
            return [
                Example("↓myString.range(of: \"Test\") \(comparison) nil")
            ]
        }
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "\\)\\s*(==|!=)\\s*nil"
        return validate(file: file, pattern: pattern, patternSyntaxKinds: [.keyword],
                        callNameSuffix: ".range", severity: configuration.severity,
                        reason: "Prefer `contains` over range(of:) comparison to nil") { expression in
                            return expression.enclosedArguments.map { $0.name } == ["of"]
        }
    }
}
