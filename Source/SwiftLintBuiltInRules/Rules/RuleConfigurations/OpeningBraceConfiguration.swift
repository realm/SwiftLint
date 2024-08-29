import SwiftLintCore

@AutoConfigParser
struct OpeningBraceConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = OpeningBraceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_multiline_type_headers")
    private(set) var ignoreMultilineTypeHeaders = false
    @ConfigurationElement(key: "ignore_multiline_statement_conditions")
    private(set) var ignoreMultilineStatementConditions = false
    @ConfigurationElement(key: "ignore_multiline_function_signatures")
    private(set) var ignoreMultilineFunctionSignatures = false
    // TODO: [08/23/2026] Remove deprecation warning after ~2 years.
    @ConfigurationElement(key: "allow_multiline_func", deprecationNotice: .suggestAlternative(
        ruleID: Parent.identifier, name: "ignore_multiline_function_signatures"))
    private(set) var allowMultilineFunc = false

    var shouldIgnoreMultilineFunctionSignatures: Bool {
        ignoreMultilineFunctionSignatures || allowMultilineFunc
    }
}
