// swiftlint:disable:next type_name
public enum ImplicitlyUnwrappedOptionalModeConfiguration: String {
    case all = "all"
    case allExceptIBOutlets = "all_except_iboutlets"

    init(value: Any) throws {
        if let string = (value as? String)?.lowercased(),
            let value = ImplicitlyUnwrappedOptionalModeConfiguration(rawValue: string) {
            self = value
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
}

public struct ImplicitlyUnwrappedOptionalConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public private(set) var severityConfiguration: SeverityConfiguration
    public private(set) var mode: ImplicitlyUnwrappedOptionalModeConfiguration

    public init(mode: ImplicitlyUnwrappedOptionalModeConfiguration, severityConfiguration: SeverityConfiguration) {
        self.mode = mode
        self.severityConfiguration = severityConfiguration
    }

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", mode: \(mode)"
    }

    public mutating func apply(configuration: Any) throws {
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
