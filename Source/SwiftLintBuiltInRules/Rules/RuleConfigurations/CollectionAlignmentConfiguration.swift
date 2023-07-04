import SwiftLintCore

struct CollectionAlignmentConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = CollectionAlignmentRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "align_colons")
    private(set) var alignColons = false

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        alignColons = configuration[$alignColons] as? Bool ?? false

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
