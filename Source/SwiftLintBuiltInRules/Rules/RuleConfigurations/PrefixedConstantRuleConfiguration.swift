struct PrefixedConstantRuleConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var onlyPrivateMembers = false

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", only_private: \(onlyPrivateMembers)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration
        }

        onlyPrivateMembers = (configuration["only_private"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
