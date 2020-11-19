private enum ConfigurationKey: String {
    case severity = "severity"
    case allowMultilineFunc = "allow_multiline_func"
}

public struct OpeningBraceConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var allowMultilineFunc = false

    public var consoleDescription: String {
        return [severityConfiguration.consoleDescription,
                "\(ConfigurationKey.allowMultilineFunc): \(allowMultilineFunc)"].joined(separator: ", ")
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        allowMultilineFunc = configuration[ConfigurationKey.allowMultilineFunc.rawValue] as? Bool ?? false
    }
}
