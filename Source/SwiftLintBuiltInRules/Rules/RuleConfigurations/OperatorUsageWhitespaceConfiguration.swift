import SwiftLintCore

struct OperatorUsageWhitespaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = OperatorUsageWhitespaceRule

    @ConfigurationElement
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "lines_look_around")
    private(set) var linesLookAround = 2
    @ConfigurationElement(key: "skip_aligned_constants")
    private(set) var skipAlignedConstants = true
    @ConfigurationElement(key: "allowed_no_space_operators")
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
