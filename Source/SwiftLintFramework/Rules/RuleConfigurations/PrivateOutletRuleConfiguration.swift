struct PrivateOutletRuleConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    var allowPrivateSet = false

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", allow_private_set: \(allowPrivateSet)"
    }

    init(allowPrivateSet: Bool) {
        self.allowPrivateSet = allowPrivateSet
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        allowPrivateSet = (configuration["allow_private_set"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
