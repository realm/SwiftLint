import SourceKittenFramework

public struct ContainsOverFilterCountRule: CallPairRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "contains_over_filter_count",
        name: "Contains Over Filter Count",
        description: "Prefer `contains` over comparing `filter(where:).count` to 0.",
        kind: .performance,
        nonTriggeringExamples: [">", "==", "!="].flatMap { operation in
            return [
                "let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1\n",
                "let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1\n"
            ]
        } +  [
            "let result = myList.contains(where: { $0 % 2 == 0 })\n",
            "let result = !myList.contains(where: { $0 % 2 == 0 })\n",
            "let result = myList.contains(10)\n"
        ],
        triggeringExamples: [">", "==", "!="].flatMap { operation in
            return [
                "let result = ↓myList.filter(where: { $0 % 2 == 0 }).count \(operation) 0\n",
                "let result = ↓myList.filter { $0 % 2 == 0 }.count \(operation) 0\n",
                "let result = ↓myList.filter(where: someFunction).count \(operation) 0\n"
            ]
        }
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "[\\}\\)]\\s*\\.count\\s*(?:!=|==|>)\\s*0"
        return validate(file: file, pattern: pattern, patternSyntaxKinds: [.identifier, .number],
                        callNameSuffix: ".filter", severity: configuration.severity)
    }
}
