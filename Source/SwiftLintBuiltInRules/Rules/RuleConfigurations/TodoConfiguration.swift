import SwiftLintCore

enum TodoKeyword: String, CaseIterable, AcceptableByConfigurationElement {
    case todo = "TODO"
    case fixme = "FIXME"

    func asOption() -> OptionType { .symbol(rawValue) }
}

struct TodoConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TodoRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only")
    private(set) var only: [TodoKeyword] = TodoKeyword.allCases

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let onlyStrings = configuration[$only] as? [String] {
            self.only = onlyStrings.compactMap { TodoKeyword(rawValue: $0) }
        }
    }
}
