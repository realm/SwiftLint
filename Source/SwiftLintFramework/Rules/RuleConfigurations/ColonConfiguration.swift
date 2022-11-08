struct ColonConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var flexibleRightSpacing = false
    private(set) var applyToDictionaries = true

    var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", flexible_right_spacing: \(flexibleRightSpacing)" +
            ", apply_to_dictionaries: \(applyToDictionaries)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        flexibleRightSpacing = configuration["flexible_right_spacing"] as? Bool == true
        applyToDictionaries = configuration["apply_to_dictionaries"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
