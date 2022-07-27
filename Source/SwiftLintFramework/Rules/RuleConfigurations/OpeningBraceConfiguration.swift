private enum ConfigurationKey: String {
    case severity = "severity"
    case allowMultilineClassStruct = "allow_multiline_class_struct"
    case allowMultilineFunc = "allow_multiline_func"
}

public struct OpeningBraceConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var allowMultilineClassStruct = false
    private(set) var allowMultilineFunc = false

    public var consoleDescription: String {
        return [severityConfiguration.consoleDescription,
                "\(ConfigurationKey.allowMultilineClassStruct): \(allowMultilineClassStruct)",
                "\(ConfigurationKey.allowMultilineFunc): \(allowMultilineFunc)"].joined(separator: ", ")
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        allowMultilineClassStruct = configuration[ConfigurationKey.allowMultilineClassStruct.rawValue] as? Bool ?? false
        allowMultilineFunc = configuration[ConfigurationKey.allowMultilineFunc.rawValue] as? Bool ?? false
    }
}
