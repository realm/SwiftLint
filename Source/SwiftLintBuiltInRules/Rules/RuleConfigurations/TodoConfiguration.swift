import SwiftLintCore

enum TodoKeyword: String, CaseIterable {
    case todo = "TODO"
    case fixme = "FIXME"
}

struct TodoConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TodoRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "only")
    private(set) var onlyKeywords: Set<String> = Set(TodoKeyword.allCases.map { $0.rawValue })

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let onlyKeywords = configuration[$onlyKeywords] as? [String] {
            self.onlyKeywords = Set(onlyKeywords)
        }
    }
}
