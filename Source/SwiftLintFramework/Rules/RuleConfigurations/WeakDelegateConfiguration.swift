public struct WeakDelegateConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var variableNames: [String]

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", only_single_muted_parameter: \()"
    }

    public init(variableNames: [String] = ["delegate"]) {
        self.variableNames = variableNames
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let configuredNames = configuration["variable_names"] as? [String] {
            if let severityString = configuration["severity"] as? String {
                try severityConfiguration.apply(configuration: severityString)
            }
variableNames = configuredNames
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
