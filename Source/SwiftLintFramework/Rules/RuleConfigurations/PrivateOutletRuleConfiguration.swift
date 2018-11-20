public struct PrivateOutletRuleConfiguration: RuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.warning)
    var allowPrivateSet = false

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", allow_private_set: \(allowPrivateSet)"
    }

    public init(allowPrivateSet: Bool) {
        self.allowPrivateSet = allowPrivateSet
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        allowPrivateSet = (configuration["allow_private_set"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
