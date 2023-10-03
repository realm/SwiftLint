import SwiftLintCore

@AutoApply
struct StatementPositionConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = StatementPositionRule

    @MakeAcceptableByConfigurationElement
    enum StatementModeConfiguration: String {
        case `default` = "default"
        case uncuddledElse = "uncuddled_else"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "statement_mode")
    private(set) var statementMode = StatementModeConfiguration.default
}
