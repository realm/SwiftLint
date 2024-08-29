import SwiftLintCore

@AutoConfigParser
struct MultilineArgumentsConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = MultilineArgumentsRule

    @AcceptableByConfigurationElement
    enum FirstArgumentLocation: String {
        case anyLine = "any_line"
        case sameLine = "same_line"
        case nextLine = "next_line"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "first_argument_location")
    private(set) var firstArgumentLocation = FirstArgumentLocation.anyLine
    @ConfigurationElement(key: "only_enforce_after_first_closure_on_first_line")
    private(set) var onlyEnforceAfterFirstClosureOnFirstLine = false
}
