import SwiftLintCore

struct TrailingClosureConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TrailingClosureRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only_single_muted_parameter")
    private(set) var onlySingleMutedParameter = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        onlySingleMutedParameter = (configuration["only_single_muted_parameter"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
