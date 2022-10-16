public struct ForWhereRuleConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.warning)
    public private(set) var allowForAsFilter = false

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", allow_for_as_filter: \(allowForAsFilter)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        allowForAsFilter = configuration["allow_for_as_filter"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
