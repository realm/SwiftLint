private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoreCommentOnlyLines = "ignore_comment_only_lines"
}

public struct FileLengthRuleConfiguration: RuleConfiguration, Equatable {
    private(set) var ignoreCommentOnlyLines: Bool
    private(set) var severityConfiguration: SeverityLevelsConfiguration

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", \(ConfigurationKey.ignoreCommentOnlyLines.rawValue): \(ignoreCommentOnlyLines)"
    }

    public init(warning: Int, error: Int?, ignoreCommentOnlyLines: Bool = false) {
        self.ignoreCommentOnlyLines = ignoreCommentOnlyLines
        self.severityConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
    }

    public mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration),
            configurationArray.isNotEmpty {
            let warning = configurationArray[0]
            let error = (configurationArray.count > 1) ? configurationArray[1] : nil
            severityConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
        } else if let configDict = configuration as? [String: Any], configDict.isNotEmpty {
            for (string, value) in configDict {
                guard let key = ConfigurationKey(rawValue: string) else {
                    throw ConfigurationError.unknownConfiguration
                }
                switch (key, value) {
                case (.error, let intValue as Int):
                    severityConfiguration.error = intValue
                case (.warning, let intValue as Int):
                    severityConfiguration.warning = intValue
                case (.ignoreCommentOnlyLines, let boolValue as Bool):
                    ignoreCommentOnlyLines = boolValue
                default:
                    throw ConfigurationError.unknownConfiguration
                }
            }
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
}
