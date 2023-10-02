import SwiftLintCore

@AutoApply
struct TrailingClosureConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TrailingClosureRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only_single_muted_parameter")
    private(set) var onlySingleMutedParameter = false
}
