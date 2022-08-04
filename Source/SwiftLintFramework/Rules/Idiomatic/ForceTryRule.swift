import SourceKittenFramework

public struct ForceTryRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_try",
        name: "Force Try",
        description: "Force tries should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            func a() throws {}
            do {
              try a()
            } catch {}
            """)
        ],
        triggeringExamples: [
            Example("""
            func a() throws {}
            ↓try! a()
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.match(pattern: "try!", with: [.keyword]).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
