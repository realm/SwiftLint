import SwiftLintCore

struct OperatorUsageWhitespaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = OperatorUsageWhitespaceRule

    @ConfigurationElement("severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement("lines_look_around")
    private(set) var linesLookAround = 2
    @ConfigurationElement("skip_aligned_constants")
    private(set) var skipAlignedConstants = true
    @ConfigurationElement("allowed_no_space_operators")
    private(set) var allowedNoSpaceOperators = ["...", "..<"]

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        linesLookAround = configuration["lines_look_around"] as? Int ?? 2
        skipAlignedConstants = configuration["skip_aligned_constants"] as? Bool ?? true
        allowedNoSpaceOperators =
            configuration["allowed_no_space_operators"] as? [String] ?? ["...", "..<"]

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
