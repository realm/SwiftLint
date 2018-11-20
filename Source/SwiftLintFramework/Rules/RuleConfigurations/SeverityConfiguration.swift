public struct SeverityConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return severity.rawValue
    }

    var severity: ViolationSeverity

    public init(_ severity: ViolationSeverity) {
        self.severity = severity
    }

    public mutating func apply(configuration: Any) throws {
        let configString = configuration as? String
        let configDict = configuration as? [String: Any]
        guard let severityString: String = configString ?? configDict?["severity"] as? String,
            let severity = severity(fromString: severityString) else {
            throw ConfigurationError.unknownConfiguration
        }
        self.severity = severity
    }

    private func severity(fromString string: String) -> ViolationSeverity? {
        return ViolationSeverity(rawValue: string.lowercased())
    }
}
