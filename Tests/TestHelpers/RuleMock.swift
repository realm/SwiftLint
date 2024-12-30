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
    public init(configuration _: Any) throws { self.init() }

    public func validate(file _: SwiftLintFile) -> [StyleViolation] { [] }
}
