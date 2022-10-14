public struct SwitchCaseAlignmentConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var indentedCases = false

    init() {}

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", indented_cases: \(indentedCases)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        indentedCases = configuration["indented_cases"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
