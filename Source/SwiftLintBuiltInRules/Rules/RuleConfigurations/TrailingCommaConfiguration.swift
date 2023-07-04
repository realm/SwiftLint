import SwiftLintCore

struct TrailingCommaConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TrailingCommaRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "mandatory_comma")
    private(set) var mandatoryComma = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        mandatoryComma = (configuration[$mandatoryComma] as? Bool == true)

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
