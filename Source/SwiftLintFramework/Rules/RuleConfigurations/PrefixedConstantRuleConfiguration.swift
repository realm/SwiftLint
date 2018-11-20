public struct PrefixedConstantRuleConfiguration: RuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.warning)
    var onlyPrivateMembers = false

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", only_private: \(onlyPrivateMembers)"
    }

    public init(onlyPrivateMembers: Bool) {
        self.onlyPrivateMembers = onlyPrivateMembers
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        onlyPrivateMembers = (configuration["only_private"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
