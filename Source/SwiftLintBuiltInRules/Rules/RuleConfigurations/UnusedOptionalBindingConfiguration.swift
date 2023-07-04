import SwiftLintCore

struct UnusedOptionalBindingConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = UnusedOptionalBindingRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_optional_try")
    private(set) var ignoreOptionalTry = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let ignoreOptionalTry = configuration[$ignoreOptionalTry] as? Bool {
            self.ignoreOptionalTry = ignoreOptionalTry
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
