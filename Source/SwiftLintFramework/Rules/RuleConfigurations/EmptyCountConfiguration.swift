private enum ConfigurationKey: String {
    case severity = "severity"
    case onlyAfterDot = "only_after_dot"
}

public struct EmptyCountConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.error)
    public private(set) var onlyAfterDot = false

    public var consoleDescription: String {
        return [severityConfiguration.consoleDescription,
                "\(ConfigurationKey.onlyAfterDot.rawValue): \(onlyAfterDot)"].joined(separator: ", ")
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        onlyAfterDot = configuration[ConfigurationKey.onlyAfterDot.rawValue] as? Bool ?? false
    }
}
