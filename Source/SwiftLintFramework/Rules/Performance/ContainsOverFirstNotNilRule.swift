import SourceKittenFramework

public struct ContainsOverFirstNotNilRule: CallPairRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "contains_over_first_not_nil",
        name: "Contains over first not nil",
        description: "Prefer `contains` over `first(where:) != nil` and `firstIndex(where:) != nil`.",
        kind: .performance,
        nonTriggeringExamples: ["first", "firstIndex"].flatMap { method in
            return [
                Example("let \(method) = myList.\(method)(where: { $0 % 2 == 0 })\n"),
                Example("let \(method) = myList.\(method) { $0 % 2 == 0 }\n")
            ]
        },
        triggeringExamples: ["first", "firstIndex"].flatMap { method in
            return ["!=", "=="].flatMap { comparison in
                return [
                    Example("↓myList.\(method) { $0 % 2 == 0 } \(comparison) nil\n"),
                    Example("↓myList.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil\n"),
                    Example("↓myList.map { $0 + 1 }.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil\n"),
                    Example("↓myList.\(method)(where: someFunction) \(comparison) nil\n"),
                    Example("↓myList.map { $0 + 1 }.\(method) { $0 % 2 == 0 } \(comparison) nil\n"),
                    Example("(↓myList.\(method) { $0 % 2 == 0 }) \(comparison) nil\n")
                ]
            }
        }
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "[\\}\\)]\\s*(==|!=)\\s*nil"
        let firstViolations = validate(file: file, pattern: pattern, patternSyntaxKinds: [.keyword],
                                       callNameSuffix: ".first", severity: configuration.severity,
                                       reason: "Prefer `contains` over `first(where:) != nil`")
        let firstIndexViolations = validate(file: file, pattern: pattern, patternSyntaxKinds: [.keyword],
                                            callNameSuffix: ".firstIndex", severity: configuration.severity,
                                            reason: "Prefer `contains` over `firstIndex(where:) != nil`")

        return firstViolations + firstIndexViolations
    }
}
