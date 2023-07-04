import SwiftLintCore

struct TrailingWhitespaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TrailingWhitespaceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignores_empty_lines")
    private(set) var ignoresEmptyLines = false
    @ConfigurationElement(key: "ignores_comments")
    private(set) var ignoresComments = true

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        ignoresEmptyLines = (configuration[$ignoresEmptyLines] as? Bool == true)
        ignoresComments = (configuration[$ignoresComments] as? Bool == true)

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
