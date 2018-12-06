import SourceKittenFramework

public struct FallthroughRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "fallthrough",
        name: "Fallthrough",
        description: "Fallthrough should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            switch foo {
            case .bar, .bar2, .bar3:
              something()
            }
            """
        ],
        triggeringExamples: [
            """
            switch foo {
            case .bar:
              ↓fallthrough
            case .bar2:
              something()
            }
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.match(pattern: "fallthrough", with: [.keyword]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
