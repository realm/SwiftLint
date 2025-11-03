import SwiftLintCore

public struct RuleMock: Rule {
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }

    public var configuration = SeverityConfiguration<Self>(.warning)

    public static let description = RuleDescription(
        identifier: "RuleMock",
        name: "",
        description: "",
        kind: .style
    )

    public init() { /* conformance for test */ }
    public init(configuration _: Any) { self.init() }

    public func validate(file _: SwiftLintFile) -> [StyleViolation] { [] }
}

public struct RuleWithLevelsMock: Rule {
    public var configuration = SeverityLevelsConfiguration<Self>(warning: 2, error: 3)

    public static let description = RuleDescription(identifier: "severity_level_mock",
                                                    name: "",
                                                    description: "",
                                                    kind: .style,
                                                    deprecatedAliases: ["mock"])

    public init() { /* conformance for test */ }
    public init(configuration: Any) throws {
        self.init()
        try self.configuration.apply(configuration: configuration)
    }

    public func validate(file _: SwiftLintFile) -> [StyleViolation] { [] }
}
