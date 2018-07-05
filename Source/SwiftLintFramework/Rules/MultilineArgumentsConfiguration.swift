import Foundation

private enum ConfigurationKey: String {
    case severity = "severity"
    case firstArgumentLocation = "first_argument_location"
    case allowFirstClosureOnSameLine = "allow_first_closure_on_same_line"
}

public struct MultilineArgumentsConfiguration: RuleConfiguration, Equatable {
    public enum FirstArgumentLocation: String {
        case anyLine = "any_line"
        case sameLine = "same_line"
        case nextLine = "next_line"

        init(value: Any) throws {
            guard
                let string = (value as? String)?.lowercased(),
                let value = FirstArgumentLocation(rawValue: string) else {
                    throw ConfigurationError.unknownConfiguration
            }

            self = value
        }
    }

    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var firstArgumentLocation = FirstArgumentLocation.anyLine
    private(set) var allowFirstClosureOnSameLine = false

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", \(ConfigurationKey.firstArgumentLocation.rawValue): \(firstArgumentLocation.rawValue)" +
            ", \(ConfigurationKey.allowFirstClosureOnSameLine.rawValue): \(allowFirstClosureOnSameLine)"
    }

    public mutating func apply(configuration: Any) throws {
        let error = ConfigurationError.unknownConfiguration

        guard let configuration = configuration as? [String: Any] else {
            throw error
        }

        for (string, value) in configuration {
            guard let key = ConfigurationKey(rawValue: string) else {
                throw error
            }

            switch (key, value) {
            case (.firstArgumentLocation, _):
                try firstArgumentLocation = FirstArgumentLocation(value: value)
            case (.severity, let stringValue as String):
                try severityConfiguration.apply(configuration: stringValue)
            case (.allowFirstClosureOnSameLine, let boolValue as Bool):
                allowFirstClosureOnSameLine = boolValue
            default:
                throw error
            }
        }
    }

    public static func == (lhs: MultilineArgumentsConfiguration,
                           rhs: MultilineArgumentsConfiguration) -> Bool {
        return lhs.severityConfiguration == rhs.severityConfiguration &&
            lhs.firstArgumentLocation == rhs.firstArgumentLocation
    }
}
