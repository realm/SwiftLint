private enum ConfigurationKey: String {
    case severity = "severity"
    case includePublicAndOpen = "include_public_and_open"
}

public struct UnusedDeclarationConfiguration: RuleConfiguration, Equatable {
    private(set) var includePublicAndOpen: Bool
    private(set) var severity: ViolationSeverity

    public var consoleDescription: String {
        return "\(ConfigurationKey.severity.rawValue): \(severity.rawValue), " +
            "\(ConfigurationKey.includePublicAndOpen.rawValue): \(includePublicAndOpen)"
    }

    public init(severity: ViolationSeverity, includePublicAndOpen: Bool) {
        self.includePublicAndOpen = includePublicAndOpen
        self.severity = severity
    }

    public mutating func apply(configuration: Any) throws {
        guard let configDict = configuration as? [String: Any], !configDict.isEmpty else {
            throw ConfigurationError.unknownConfiguration
        }

        for (string, value) in configDict {
            guard let key = ConfigurationKey(rawValue: string) else {
                throw ConfigurationError.unknownConfiguration
            }
            switch (key, value) {
            case (.severity, let stringValue as String):
                if let severityValue = ViolationSeverity(rawValue: stringValue) {
                    severity = severityValue
                } else {
                    throw ConfigurationError.unknownConfiguration
                }
            case (.includePublicAndOpen, let boolValue as Bool):
                includePublicAndOpen = boolValue
            default:
                throw ConfigurationError.unknownConfiguration
            }
        }
    }
}
