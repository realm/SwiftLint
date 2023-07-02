import SwiftLintCore

private enum ConfigurationKey: String {
    case severity = "severity"
    case firstArgumentLocation = "first_argument_location"
    case onlyEnforceAfterFirstClosureOnFirstLine = "only_enforce_after_first_closure_on_first_line"
}

struct MultilineArgumentsConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = MultilineArgumentsRule

    enum FirstArgumentLocation: String, AcceptableByConfigurationElement {
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

        func asOption() -> OptionType { .symbol(rawValue) }
    }

    @ConfigurationElement
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: ConfigurationKey.firstArgumentLocation.rawValue)
    private(set) var firstArgumentLocation = FirstArgumentLocation.anyLine
    @ConfigurationElement(key: ConfigurationKey.onlyEnforceAfterFirstClosureOnFirstLine.rawValue)
    private(set) var onlyEnforceAfterFirstClosureOnFirstLine = false

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
