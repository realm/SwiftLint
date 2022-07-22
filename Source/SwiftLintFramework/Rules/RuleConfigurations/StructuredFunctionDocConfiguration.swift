private enum ConfigurationKey: String {
    case severity = "severity"
    case maxSummaryLineCount = "max_summary_line_count"
    case minimalNumberOfParameters = "minimal_number_of_parameters"
}

public struct StructuredFunctionDocConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var maxSummaryLineCount = 2
    private(set) var minimalNumberOfParameters = 3

    public var consoleDescription: String {
        severityConfiguration.consoleDescription +
        ", \(ConfigurationKey.maxSummaryLineCount.rawValue): \(maxSummaryLineCount)" +
        ", \(ConfigurationKey.minimalNumberOfParameters.rawValue): \(minimalNumberOfParameters)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        for (string, value) in configuration {
            guard let key = ConfigurationKey(rawValue: string) else {
                throw ConfigurationError.generic("Unknown configuration: \(string)")
            }

            switch (key, value) {
            case (.maxSummaryLineCount, let intValue as Int):
                guard intValue > 0 else {
                    throw ConfigurationError.generic(
                        "\(ConfigurationKey.maxSummaryLineCount.rawValue) must be greater than 0.")
                }
                maxSummaryLineCount = intValue
            case (.severity, let stringValue as String):
                try severityConfiguration.apply(configuration: stringValue)
            case (.minimalNumberOfParameters, let intValue as Int):
                minimalNumberOfParameters = intValue
            default:
                throw ConfigurationError.unknownConfiguration
            }
        }
    }
}
