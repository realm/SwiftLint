import SourceKittenFramework

public struct ContainsOverFirstNotNilRule: CallPairRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "contains_over_first_not_nil",
        name: "Contains over first not nil",
        description: "Prefer `contains` over `first(where:) != nil`",
        kind: .performance,
        nonTriggeringExamples: [
            "let first = myList.first(where: { $0 % 2 == 0 })\n",
            "let first = myList.first { $0 % 2 == 0 }\n"
        ],
        triggeringExamples: [
            "↓myList.first { $0 % 2 == 0 } != nil\n",
            "↓myList.first(where: { $0 % 2 == 0 }) != nil\n",
            "↓myList.map { $0 + 1 }.first(where: { $0 % 2 == 0 }) != nil\n",
            "↓myList.first(where: someFunction) != nil\n",
            "↓myList.map { $0 + 1 }.first { $0 % 2 == 0 } != nil\n",
            "(↓myList.first { $0 % 2 == 0 }) != nil\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return validate(file: file,
                        pattern: "[\\}\\)]\\s*!=\\s*nil",
                        patternSyntaxKinds: [.keyword],
                        callNameSuffix: ".first",
                        severity: configuration.severity)
    }
}
