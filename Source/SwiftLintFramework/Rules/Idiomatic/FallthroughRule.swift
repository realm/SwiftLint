import SourceKittenFramework

public struct FallthroughRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "fallthrough",
        name: "Fallthrough",
        description: "Fallthrough should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            switch foo {
            case .bar, .bar2, .bar3:
              something()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            switch foo {
            case .bar:
              ↓fallthrough
            case .bar2:
              something()
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.match(pattern: "fallthrough", with: [.keyword]).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
