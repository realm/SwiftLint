public struct LegacyRandomRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "legacy_random",
        name: "Legacy Random",
        description: "Prefer using `type.random(in:)` over legacy functions.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("Int.random(in: 0..<10)\n"),
            Example("Double.random(in: 8.6...111.34)\n"),
            Example("Float.random(in: 0 ..< 1)\n")
        ],
        triggeringExamples: [
            Example("↓arc4random(10)\n"),
            Example("↓arc4random_uniform(83)\n"),
            Example("↓drand48(52)\n")
        ]
    )

    private let legacyRandomFunctions: Set<String> = [
        "arc4random",
        "arc4random_uniform",
        "drand48"
    ]

    public func validate(
        file: SwiftLintFile,
        kind: SwiftExpressionKind,
        dictionary: SourceKittenDictionary
    ) -> [StyleViolation] {
        guard containsViolation(kind: kind, dictionary: dictionary),
        let offset = dictionary.offset else {
            return []
        }

        let location = Location(file: file, byteOffset: offset)
        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: location)
        ]
    }

    private func containsViolation(kind: SwiftExpressionKind, dictionary: SourceKittenDictionary) -> Bool {
        guard kind == .call,
            let name = dictionary.name,
            legacyRandomFunctions.contains(name) else {
            return false
        }

        return true
    }
}
