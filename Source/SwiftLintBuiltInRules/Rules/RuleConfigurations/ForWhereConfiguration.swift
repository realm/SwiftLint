import SwiftLintCore

struct ForWhereConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ForWhereRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allow_for_as_filter")
    private(set) var allowForAsFilter = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        allowForAsFilter = configuration["allow_for_as_filter"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
