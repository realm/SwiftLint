private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoresDefaultParameters = "ignores_default_parameters"
}

public struct FunctionParameterCountConfiguration: RuleConfiguration, Equatable {
    private(set) var ignoresDefaultParameters: Bool
    private(set) var severityConfiguration: SeverityLevelsConfiguration

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
        "\(ConfigurationKey.ignoresDefaultParameters.rawValue): \(ignoresDefaultParameters)"
    }

    public init(warning: Int, error: Int?, ignoresDefaultParameters: Bool = true) {
        self.ignoresDefaultParameters = ignoresDefaultParameters
        self.severityConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
    }

    public mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration),
            !configurationArray.isEmpty {
            let warning = configurationArray[0]
            let error = (configurationArray.count > 1) ? configurationArray[1] : nil
            severityConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
        } else if let configDict = configuration as? [String: Any], !configDict.isEmpty {
            for (string, value) in configDict {
                guard let key = ConfigurationKey(rawValue: string) else {
                    throw ConfigurationError.unknownConfiguration
                }
                switch (key, value) {
                case (.error, let intValue as Int):
                    severityConfiguration.error = intValue
                case (.warning, let intValue as Int):
                    severityConfiguration.warning = intValue
                case (.ignoresDefaultParameters, let boolValue as Bool):
                    ignoresDefaultParameters = boolValue
                default:
                    throw ConfigurationError.unknownConfiguration
                }
            }
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
}
