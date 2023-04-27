struct TrailingClosureConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var onlySingleMutedParameter: Bool

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)"
            + ", only_single_muted_parameter: \(onlySingleMutedParameter)"
    }

    init(onlySingleMutedParameter: Bool = false) {
        self.onlySingleMutedParameter = onlySingleMutedParameter
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        onlySingleMutedParameter = (configuration["only_single_muted_parameter"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
