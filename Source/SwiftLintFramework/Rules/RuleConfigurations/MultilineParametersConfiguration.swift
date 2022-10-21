public struct MultilineParametersConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.warning)
    public private(set) var allowsSingleLine = true

    public var consoleDescription: String {
        severityConfiguration.consoleDescription
            + ", allowsSingleLine: \(allowsSingleLine)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        allowsSingleLine = configuration["allows_single_line"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
