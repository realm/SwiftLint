import SwiftLintCore

struct OpeningBraceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = OpeningBraceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_multiline_func")
    private(set) var allowMultilineFunc = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        allowMultilineFunc = configuration[$allowMultilineFunc] as? Bool ?? false
    }
}
