private enum ConfigurationKey: String {
    case severity = "severity"
    case includePublicAndOpen = "include_public_and_open"
    case relatedUSRsToSkip = "related_usrs_to_skip"
}

struct UnusedDeclarationConfiguration: RuleConfiguration, Equatable {
    private(set) var includePublicAndOpen: Bool
    private(set) var severityConfiguration: SeverityConfiguration
    private(set) var relatedUSRsToSkip: Set<String>

    var consoleDescription: String {
        return "\(ConfigurationKey.severity.rawValue): \(severityConfiguration.severity.rawValue), " +
            "\(ConfigurationKey.includePublicAndOpen.rawValue): \(includePublicAndOpen), " +
            "\(ConfigurationKey.relatedUSRsToSkip.rawValue): \(relatedUSRsToSkip.sorted())"
    }

    init(severity: ViolationSeverity, includePublicAndOpen: Bool, relatedUSRsToSkip: Set<String>) {
        self.includePublicAndOpen = includePublicAndOpen
        self.severityConfiguration = SeverityConfiguration(severity)
        self.relatedUSRsToSkip = relatedUSRsToSkip
    }

    mutating func apply(configuration: Any) throws {
        guard let configDict = configuration as? [String: Any], configDict.isNotEmpty else {
            throw ConfigurationError.unknownConfiguration
        }

        for (string, value) in configDict {
            guard let key = ConfigurationKey(rawValue: string) else {
                throw ConfigurationError.unknownConfiguration
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
                    throw ConfigurationError.unknownConfiguration
                }
            default:
                throw ConfigurationError.unknownConfiguration
            }
        }
    }
}
