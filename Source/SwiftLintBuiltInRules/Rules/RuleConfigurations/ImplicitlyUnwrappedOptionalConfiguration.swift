import SwiftLintCore

struct ImplicitlyUnwrappedOptionalConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ImplicitlyUnwrappedOptionalRule

    // swiftlint:disable:next type_name
    enum ImplicitlyUnwrappedOptionalModeConfiguration: String, AcceptableByConfigurationElement {
        case all = "all"
        case allExceptIBOutlets = "all_except_iboutlets"

        init(value: Any) throws {
            if let string = (value as? String)?.lowercased(),
               let value = Self(rawValue: string) {
                self = value
            } else {
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
        }

        func asOption() -> OptionType { .symbol(rawValue) }
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "mode")
    private(set) var mode = ImplicitlyUnwrappedOptionalModeConfiguration.allExceptIBOutlets

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let modeString = configuration["mode"] {
            try mode = ImplicitlyUnwrappedOptionalModeConfiguration(value: modeString)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
