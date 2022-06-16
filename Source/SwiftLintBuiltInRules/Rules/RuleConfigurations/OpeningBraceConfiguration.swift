private enum ConfigurationKey: String {
    case severity = "severity"
    case allowMultilineFunc = "allow_multiline_func"
}

struct OpeningBraceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = OpeningBraceRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var allowMultilineFunc = false

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        ConfigurationKey.allowMultilineFunc.rawValue => .flag(allowMultilineFunc)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        allowMultilineFunc = configuration[ConfigurationKey.allowMultilineFunc.rawValue] as? Bool ?? false
    }
}
