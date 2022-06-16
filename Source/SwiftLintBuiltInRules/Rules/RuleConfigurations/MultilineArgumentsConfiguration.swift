private enum ConfigurationKey: String {
    case severity = "severity"
    case firstArgumentLocation = "first_argument_location"
    case onlyEnforceAfterFirstClosureOnFirstLine = "only_enforce_after_first_closure_on_first_line"
}

struct MultilineArgumentsConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = MultilineArgumentsRule

    enum FirstArgumentLocation: String {
        case anyLine = "any_line"
        case sameLine = "same_line"
        case nextLine = "next_line"

        init(value: Any) throws {
            guard
                let string = (value as? String)?.lowercased(),
                let value = Self(rawValue: string) else {
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }

            self = value
        }
    }

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var firstArgumentLocation = FirstArgumentLocation.anyLine
    private(set) var onlyEnforceAfterFirstClosureOnFirstLine = false

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        ConfigurationKey.firstArgumentLocation.rawValue => .string(firstArgumentLocation.rawValue)
        ConfigurationKey.onlyEnforceAfterFirstClosureOnFirstLine.rawValue => .flag(onlyEnforceAfterFirstClosureOnFirstLine)
        // swiftlint:disable:previous line_length
    }

    mutating func apply(configuration: Any) throws {
        let error = Issue.unknownConfiguration(ruleID: Parent.identifier)

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
