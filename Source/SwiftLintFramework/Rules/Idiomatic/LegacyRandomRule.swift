import SourceKittenFramework

public struct LegacyRandomRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "legacy_random",
        name: "Legacy Random",
        description: "Prefer using `type.random(in:)` over legacy functions.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            "Int.random(in: 0..<10)\n",
            "Double.random(in: 8.6...111.34)\n",
            "Float.random(in: 0 ..< 1)\n"
        ],
        triggeringExamples: [
            "↓arc4random(10)\n",
            "↓arc4random_uniform(83)\n",
            "↓drand48(52)\n"
        ]
    )

    private let legacyRandomFunctions: Set<String> = [
        "arc4random",
        "arc4random_uniform",
        "drand48"
    ]

    public func validate(
        file: File,
        kind: SwiftExpressionKind,
        dictionary: [String: SourceKitRepresentable]
    ) -> [StyleViolation] {
        guard containsViolation(kind: kind, dictionary: dictionary),
        let offset = dictionary.offset else {
            return []
        }

        let location = Location(file: file, byteOffset: offset)
        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: location)
        ]
    }

    private func containsViolation(kind: SwiftExpressionKind, dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard kind == .call,
            let name = dictionary.name,
            legacyRandomFunctions.contains(name) else {
            return false
        }

        return true
    }
}
