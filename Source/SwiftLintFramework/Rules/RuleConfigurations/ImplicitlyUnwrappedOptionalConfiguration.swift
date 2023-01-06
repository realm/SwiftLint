// swiftlint:disable:next type_name
enum ImplicitlyUnwrappedOptionalModeConfiguration: String {
    case all = "all"
    case allExceptIBOutlets = "all_except_iboutlets"

    init(value: Any) throws {
        if let string = (value as? String)?.lowercased(),
            let value = Self(rawValue: string) {
            self = value
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
}

struct ImplicitlyUnwrappedOptionalConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration: SeverityConfiguration
    private(set) var mode: ImplicitlyUnwrappedOptionalModeConfiguration

    init(mode: ImplicitlyUnwrappedOptionalModeConfiguration, severityConfiguration: SeverityConfiguration) {
        self.mode = mode
        self.severityConfiguration = severityConfiguration
    }

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" +
            ", mode: \(mode.rawValue)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let modeString = configuration["mode"] {
            try mode = ImplicitlyUnwrappedOptionalModeConfiguration(value: modeString)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
