import SwiftLintCore

struct ExplicitTypeInterfaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ExplicitTypeInterfaceRule

    enum VariableKind: String, CaseIterable, AcceptableByConfigurationElement {
        case instance
        case local
        case `static`
        case `class`

        static let all = Set(allCases)

        func asOption() -> SwiftLintCore.OptionType { .symbol(rawValue) }
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = [VariableKind]()
    @ConfigurationElement(key: "allow_redundancy")
    private(set) var allowRedundancy = false

    var allowedKinds: Set<VariableKind> {
        VariableKind.all.subtracting(excluded)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
        for (key, value) in configuration {
            switch (key, value) {
            case ($severityConfiguration, let severityString as String):
                try severityConfiguration.apply(configuration: severityString)
            case ($excluded, let excludedStrings as [String]):
                self.excluded = excludedStrings.compactMap(VariableKind.init).unique
            case ($allowRedundancy, let allowRedundancy as Bool):
                self.allowRedundancy = allowRedundancy
            default:
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
        }
    }
}
