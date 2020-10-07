public struct TestCaseAccessibilityConfiguration: RuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.warning)
    public private(set) var methodPrefixes: Set<String> = []

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
        	", method_prefixes: [\(methodPrefixes)]"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let methodPrefixes = configuration["method_prefixes"] as? [String] {
            self.methodPrefixes = Set(methodPrefixes)
        }
    }

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }
}
