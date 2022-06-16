struct FileNameNoSpaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = FileNameNoSpaceRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    private(set) var excluded = Set<String>()

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "excluded" => .list(excluded.sorted().map { .string($0) })
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severity = configurationDict["severity"] {
            try severityConfiguration.apply(configuration: severity)
        }
        if let excluded = [String].array(of: configurationDict["excluded"]) {
            self.excluded = Set(excluded)
        }
    }
}
