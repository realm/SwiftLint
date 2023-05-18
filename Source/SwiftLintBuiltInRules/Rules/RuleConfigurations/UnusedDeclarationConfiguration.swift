private enum ConfigurationKey: String {
    case severity = "severity"
    case includePublicAndOpen = "include_public_and_open"
    case relatedUSRsToSkip = "related_usrs_to_skip"
}

struct UnusedDeclarationConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration.error
    private(set) var includePublicAndOpen = false
    private(set) var relatedUSRsToSkip = Set(["s:7SwiftUI15PreviewProviderP"])

    var consoleDescription: String {
        return "\(ConfigurationKey.severity.rawValue): \(severityConfiguration.severity.rawValue), " +
            "\(ConfigurationKey.includePublicAndOpen.rawValue): \(includePublicAndOpen), " +
            "\(ConfigurationKey.relatedUSRsToSkip.rawValue): \(relatedUSRsToSkip.sorted())"
    }

    mutating func apply(configuration: Any) throws {
        guard let configDict = configuration as? [String: Any], configDict.isNotEmpty else {
            throw Issue.unknownConfiguration
        }

        for (string, value) in configDict {
            guard let key = ConfigurationKey(rawValue: string) else {
                throw Issue.unknownConfiguration
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
                    throw Issue.unknownConfiguration
                }
            default:
                throw Issue.unknownConfiguration
            }
        }
    }
}
