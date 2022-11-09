private enum ConfigurationKey: String {
    case severity = "severity"
    case firstArgumentLocation = "first_argument_location"
    case onlyEnforceAfterFirstClosureOnFirstLine = "only_enforce_after_first_closure_on_first_line"
}

struct MultilineArgumentsConfiguration: RuleConfiguration, Equatable {
    enum FirstArgumentLocation: String {
        case anyLine = "any_line"
        case sameLine = "same_line"
        case nextLine = "next_line"

        init(value: Any) throws {
            guard
                let string = (value as? String)?.lowercased(),
                let value = Self(rawValue: string) else {
                    throw ConfigurationError.unknownConfiguration
            }

            self = value
        }
    }

    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var firstArgumentLocation = FirstArgumentLocation.anyLine
    private(set) var onlyEnforceAfterFirstClosureOnFirstLine = false

    var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", \(ConfigurationKey.firstArgumentLocation.rawValue): \(firstArgumentLocation.rawValue)" +
            ", \(ConfigurationKey.onlyEnforceAfterFirstClosureOnFirstLine.rawValue): \(onlyEnforceAfterFirstClosureOnFirstLine)"
            // swiftlint:disable:previous line_length
    }

    mutating func apply(configuration: Any) throws {
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
            case (.onlyEnforceAfterFirstClosureOnFirstLine, let boolValue as Bool):
                onlyEnforceAfterFirstClosureOnFirstLine = boolValue
            default:
                throw error
            }
        }
    }
}
