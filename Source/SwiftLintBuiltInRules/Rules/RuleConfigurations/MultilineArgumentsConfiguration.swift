import SwiftLintCore

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

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "first_argument_location")
    private(set) var firstArgumentLocation = FirstArgumentLocation.anyLine
    @ConfigurationElement(key: "only_enforce_after_first_closure_on_first_line")
    private(set) var onlyEnforceAfterFirstClosureOnFirstLine = false

    mutating func apply(configuration: Any) throws {
        let error = Issue.unknownConfiguration(ruleID: Parent.identifier)

        guard let configuration = configuration as? [String: Any] else {
            throw error
        }

        for (string, value) in configuration {
            switch (string, value) {
            case ($firstArgumentLocation, _):
                try firstArgumentLocation = FirstArgumentLocation(value: value)
            case ($severityConfiguration, let stringValue as String):
                try severityConfiguration.apply(configuration: stringValue)
            case ($onlyEnforceAfterFirstClosureOnFirstLine, let boolValue as Bool):
                onlyEnforceAfterFirstClosureOnFirstLine = boolValue
            default:
                throw error
            }
        }
    }
}
