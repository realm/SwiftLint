import SourceKittenFramework

public struct FlatMapOverMapReduceRule: CallPairRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "flatmap_over_map_reduce",
        name: "FlatMap over map and reduce",
        description: "Prefer `flatMap` over `map` followed by `reduce([], +)`.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("let foo = bar.map { $0.count }.reduce(0, +)"),
            Example("let foo = bar.flatMap { $0.array }")
        ],
        triggeringExamples: [
            Example("let foo = ↓bar.map { $0.array }.reduce([], +)")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "[\\}\\)]\\s*\\.reduce\\s*\\(\\[\\s*\\],\\s*\\+\\s*\\)"
        return validate(file: file, pattern: pattern, patternSyntaxKinds: [.identifier],
                        callNameSuffix: ".map", severity: configuration.severity)
    }
}
