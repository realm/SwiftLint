import SwiftLintCore

@AutoApply
struct XCTSpecificMatcherConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = XCTSpecificMatcherRule

    @MakeAcceptableByConfigurationElement
    enum Matcher: String, CaseIterable {
        case oneArgumentAsserts = "one-argument-asserts"
        case twoArgumentAsserts = "two-argument-asserts"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "matchers")
    private(set) var matchers = Matcher.allCases
}
