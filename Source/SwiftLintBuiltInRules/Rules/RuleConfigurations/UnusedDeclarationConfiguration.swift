import SwiftLintCore

private enum ConfigurationKey: String {
    case severity = "severity"
    case includePublicAndOpen = "include_public_and_open"
    case relatedUSRsToSkip = "related_usrs_to_skip"
}

struct UnusedDeclarationConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = UnusedDeclarationRule

    @ConfigurationElement("severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.error
    @ConfigurationElement(ConfigurationKey.includePublicAndOpen.rawValue)
    private(set) var includePublicAndOpen = false
    @ConfigurationElement(ConfigurationKey.relatedUSRsToSkip.rawValue)
    private(set) var relatedUSRsToSkip = Set(["s:7SwiftUI15PreviewProviderP"])

    mutating func apply(configuration: Any) throws {
        guard let configDict = configuration as? [String: Any], configDict.isNotEmpty else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        for (string, value) in configDict {
            guard let key = ConfigurationKey(rawValue: string) else {
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
            switch (key, value) {
            case (.severity, let stringValue as String):
                try severityConfiguration.apply(configuration: stringValue)
            case (.includePublicAndOpen, let boolValue as Bool):
                includePublicAndOpen = boolValue
            case (.relatedUSRsToSkip, let value):
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
