struct PrivateOverFilePrivateRuleConfiguration: SeverityBasedRuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.warning)
    var validateExtensions = false

    var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", validate_extensions: \(validateExtensions)"
    }

    // MARK: - RuleConfiguration

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        validateExtensions = configuration["validate_extensions"] as? Bool ?? false
    }
}
