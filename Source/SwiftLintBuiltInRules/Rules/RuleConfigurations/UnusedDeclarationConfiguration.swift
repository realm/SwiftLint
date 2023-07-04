import SwiftLintCore

struct UnusedDeclarationConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = UnusedDeclarationRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.error
    @ConfigurationElement(key: "include_public_and_open")
    private(set) var includePublicAndOpen = false
    @ConfigurationElement(key: "related_usrs_to_skip")
    private(set) var relatedUSRsToSkip = Set(["s:7SwiftUI15PreviewProviderP"])

    mutating func apply(configuration: Any) throws {
        guard let configDict = configuration as? [String: Any], configDict.isNotEmpty else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        for (string, value) in configDict {
            switch (string, value) {
            case ($severityConfiguration, let stringValue as String):
                try severityConfiguration.apply(configuration: stringValue)
            case ($includePublicAndOpen, let boolValue as Bool):
                includePublicAndOpen = boolValue
            case ($relatedUSRsToSkip, let value):
                if let usrs = [String].array(of: value) {
                    relatedUSRsToSkip.formUnion(usrs)
                } else {
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
                }
            default:
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
        }
    }
}
