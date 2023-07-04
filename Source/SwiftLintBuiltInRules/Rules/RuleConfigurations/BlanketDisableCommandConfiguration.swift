import SwiftLintCore

struct BlanketDisableCommandConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = BlanketDisableCommandRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allowed_rules")
    private(set) var allowedRuleIdentifiers: Set<String> = [
        "file_header",
        "file_length",
        "file_name",
        "file_name_no_space",
        "single_test_class"
    ]
    @ConfigurationElement(key: "always_blanket_disable")
    private(set) var alwaysBlanketDisableRuleIdentifiers: Set<String> = []

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let allowedRuleIdentifiers = configuration[$allowedRuleIdentifiers] as? [String] {
            self.allowedRuleIdentifiers = Set(allowedRuleIdentifiers)
        }

        if let alwaysBlanketDisableRuleIdentifiers = configuration[$alwaysBlanketDisableRuleIdentifiers] as? [String] {
            self.alwaysBlanketDisableRuleIdentifiers = Set(alwaysBlanketDisableRuleIdentifiers)
        }
    }
}
