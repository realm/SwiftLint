struct SwitchCaseAlignmentConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var indentedCases = false

    init() {}

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", indented_cases: \(indentedCases)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        indentedCases = configuration["indented_cases"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
