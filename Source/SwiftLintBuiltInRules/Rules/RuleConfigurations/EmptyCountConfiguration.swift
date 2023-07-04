import SwiftLintCore

struct EmptyCountConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = EmptyCountRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.error)
    @ConfigurationElement(key: "only_after_dot")
    private(set) var onlyAfterDot = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        onlyAfterDot = configuration[$onlyAfterDot] as? Bool ?? false
    }
}
