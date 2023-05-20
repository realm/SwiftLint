struct PrivateOutletConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = PrivateOutletRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var allowPrivateSet = false

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", allow_private_set: \(allowPrivateSet)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        allowPrivateSet = (configuration["allow_private_set"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
