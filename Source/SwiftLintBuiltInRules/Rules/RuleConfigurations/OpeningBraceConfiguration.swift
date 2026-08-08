import SwiftLintCore

@AutoConfigParser
struct OpeningBraceConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_multiline_type_headers")
    private(set) var ignoreMultilineTypeHeaders = false
    @ConfigurationElement(key: "ignore_multiline_statement_conditions")
    private(set) var ignoreMultilineStatementConditions = false
    @ConfigurationElement(key: "ignore_multiline_function_signatures")
    private(set) var ignoreMultilineFunctionSignatures = false
}
