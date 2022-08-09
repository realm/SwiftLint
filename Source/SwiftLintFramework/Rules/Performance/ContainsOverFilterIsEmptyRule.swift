import SourceKittenFramework

public struct ContainsOverFilterIsEmptyRule: CallPairRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "contains_over_filter_is_empty",
        name: "Contains Over Filter Is Empty",
        description: "Prefer `contains` over using `filter(where:).isEmpty`",
        kind: .performance,
        nonTriggeringExamples: [">", "==", "!="].flatMap { operation in
            return [
                Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1\n"),
                Example("let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1\n")
            ]
        } + [
            Example("let result = myList.contains(where: { $0 % 2 == 0 })\n"),
            Example("let result = !myList.contains(where: { $0 % 2 == 0 })\n"),
            Example("let result = myList.contains(10)\n")
        ],
        triggeringExamples: [
            Example("let result = ↓myList.filter(where: { $0 % 2 == 0 }).isEmpty\n"),
            Example("let result = !↓myList.filter(where: { $0 % 2 == 0 }).isEmpty\n"),
            Example("let result = ↓myList.filter { $0 % 2 == 0 }.isEmpty\n"),
            Example("let result = ↓myList.filter(where: someFunction).isEmpty\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "[\\}\\)]\\s*\\.isEmpty\\b"
        return validate(file: file, pattern: pattern, patternSyntaxKinds: [.identifier],
                        callNameSuffix: ".filter", severity: configuration.severity)
    }
}
