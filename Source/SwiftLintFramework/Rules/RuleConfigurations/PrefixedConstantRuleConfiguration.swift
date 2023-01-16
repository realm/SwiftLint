struct PrefixedConstantRuleConfiguration: SeverityBasedRuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.warning)
    var onlyPrivateMembers = false

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", only_private: \(onlyPrivateMembers)"
    }

    init(onlyPrivateMembers: Bool) {
        self.onlyPrivateMembers = onlyPrivateMembers
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        onlyPrivateMembers = (configuration["only_private"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
