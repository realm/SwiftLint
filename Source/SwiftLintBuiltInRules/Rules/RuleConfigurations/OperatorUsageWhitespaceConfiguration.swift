import SwiftLintCore

@AutoConfigParser
struct OperatorUsageWhitespaceConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = OperatorUsageWhitespaceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "lines_look_around")
    private(set) var linesLookAround = 2
    @ConfigurationElement(key: "skip_aligned_constants")
    private(set) var skipAlignedConstants = true
    @ConfigurationElement(key: "allowed_no_space_operators")
    private(set) var allowedNoSpaceOperators = ["...", "..<"]
}
