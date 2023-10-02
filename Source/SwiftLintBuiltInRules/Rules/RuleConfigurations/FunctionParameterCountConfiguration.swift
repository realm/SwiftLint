import SwiftLintCore

@AutoApply
struct FunctionParameterCountConfiguration: RuleConfiguration, Equatable {
    typealias Parent = FunctionParameterCountRule

    @ConfigurationElement
    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(warning: 5, error: 8)
    @ConfigurationElement(key: "ignores_default_parameters")
    private(set) var ignoresDefaultParameters = true
}
