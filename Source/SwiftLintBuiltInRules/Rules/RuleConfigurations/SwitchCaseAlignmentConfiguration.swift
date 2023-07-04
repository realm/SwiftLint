import SwiftLintCore

struct SwitchCaseAlignmentConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = SwitchCaseAlignmentRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "indented_cases")
    private(set) var indentedCases = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        indentedCases = configuration[$indentedCases] as? Bool ?? false

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
