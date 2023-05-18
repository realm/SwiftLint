struct ConditionalReturnsOnNewlineConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ConditionalReturnsOnNewlineRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var ifOnly = false

    var consoleDescription: String {
        return ["severity: \(severityConfiguration.consoleDescription)", "if_only: \(ifOnly)"].joined(separator: ", ")
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        ifOnly = configuration["if_only"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
