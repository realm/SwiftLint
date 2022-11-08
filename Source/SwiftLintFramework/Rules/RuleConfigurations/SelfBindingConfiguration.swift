private enum ConfigurationKey: String {
    case severity = "severity"
    case bindIdentifier = "bind_identifier"
}

struct SelfBindingConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var bindIdentifier = "self"

    var consoleDescription: String {
        return [severityConfiguration.consoleDescription,
                "\(ConfigurationKey.bindIdentifier): \(bindIdentifier)"].joined(separator: ", ")
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        bindIdentifier = configuration[ConfigurationKey.bindIdentifier.rawValue] as? String ?? "self"
    }
}
