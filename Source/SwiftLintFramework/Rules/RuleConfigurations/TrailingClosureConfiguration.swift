public struct TrailingClosureConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.warning)
    public private(set) var onlySingleMutedParameter: Bool

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", only_single_muted_parameter: \(onlySingleMutedParameter)"
    }

    public init(onlySingleMutedParameter: Bool = false) {
        self.onlySingleMutedParameter = onlySingleMutedParameter
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        onlySingleMutedParameter = (configuration["only_single_muted_parameter"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
