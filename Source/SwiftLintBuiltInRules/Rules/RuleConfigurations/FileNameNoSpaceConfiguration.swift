struct FileNameNoSpaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = FileNameNoSpaceRule

    var consoleDescription: String {
        return "(severity) \(severityConfiguration.consoleDescription), " +
            "excluded: \(excluded.sorted())"
    }

    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    private(set) var excluded = Set<String>()

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
