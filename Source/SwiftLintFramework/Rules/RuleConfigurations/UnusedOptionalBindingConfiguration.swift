public struct UnusedOptionalBindingConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.warning)
    public private(set) var ignoreOptionalTry: Bool

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", ignore_optional_try: \(ignoreOptionalTry)"
    }

    public init(ignoreOptionalTry: Bool) {
        self.ignoreOptionalTry = ignoreOptionalTry
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let ignoreOptionalTry = configuration["ignore_optional_try"] as? Bool {
            self.ignoreOptionalTry = ignoreOptionalTry
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
