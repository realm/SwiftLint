import SwiftLintCore

@AutoConfigParser
struct FunctionParameterCountConfiguration: RuleConfiguration {
    typealias Parent = FunctionParameterCountRule

    @ConfigurationElement(inline: true)
    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(warning: 5, error: 8)
    @ConfigurationElement(key: "ignores_default_parameters")
    private(set) var ignoresDefaultParameters = true
}
