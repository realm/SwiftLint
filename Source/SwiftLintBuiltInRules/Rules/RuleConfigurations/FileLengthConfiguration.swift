private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoreCommentOnlyLines = "ignore_comment_only_lines"
}

struct FileLengthConfiguration: RuleConfiguration, Equatable {
    typealias Parent = FileLengthRule

    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(warning: 400, error: 1000)
    private(set) var ignoreCommentOnlyLines = false

    var parameterDescription: RuleConfigurationDescription {
        severityConfiguration
        ConfigurationKey.ignoreCommentOnlyLines.rawValue => .flag(ignoreCommentOnlyLines)
    }

    mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration),
            configurationArray.isNotEmpty {
            let warning = configurationArray[0]
            let error = (configurationArray.count > 1) ? configurationArray[1] : nil
            severityConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
        } else if let configDict = configuration as? [String: Any], configDict.isNotEmpty {
            for (string, value) in configDict {
                guard let key = ConfigurationKey(rawValue: string) else {
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
                }
                switch (key, value) {
                case (.error, let intValue as Int):
                    severityConfiguration.error = intValue
                case (.warning, let intValue as Int):
                    severityConfiguration.warning = intValue
                case (.ignoreCommentOnlyLines, let boolValue as Bool):
                    ignoreCommentOnlyLines = boolValue
                default:
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
                }
            }
        } else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
    }
}
