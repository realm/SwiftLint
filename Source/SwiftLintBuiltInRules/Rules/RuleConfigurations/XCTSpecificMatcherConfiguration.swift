import SwiftLintCore

struct XCTSpecificMatcherConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = XCTSpecificMatcherRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "matchers")
    private(set) var matchers = Matcher.allCases

    enum Matcher: String, Hashable, CaseIterable, AcceptableByConfigurationElement {
        case oneArgumentAsserts = "one-argument-asserts"
        case twoArgumentAsserts = "two-argument-asserts"

        func asOption() -> OptionType { .symbol(rawValue) }
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let matchers = configuration[$matchers] as? [String] {
            self.matchers = matchers.compactMap(Matcher.init)
        }
    }
}
