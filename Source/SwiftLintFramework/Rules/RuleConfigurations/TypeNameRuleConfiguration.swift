struct TypeNameRuleConfiguration: RuleConfiguration, Equatable {
    private(set) var nameConfiguration = NameConfiguration(minLengthWarning: 3,
                                                           minLengthError: 0,
                                                           maxLengthWarning: 40,
                                                           maxLengthError: 1000)
    private(set) var validateProtocols = true

    var consoleDescription: String {
        return nameConfiguration.consoleDescription + ", validate_protocols: \(validateProtocols)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        try nameConfiguration.apply(configuration: configuration)

        if let validateProtocols = configuration["validate_protocols"] as? Bool {
            self.validateProtocols = validateProtocols
        }
    }
}
