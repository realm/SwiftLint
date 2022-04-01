struct OperatorUsageWhitespaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = OperatorUsageWhitespaceRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var linesLookAround = 2
    private(set) var skipAlignedConstants = true
    private(set) var allowedNoSpaceOperators: [String] = ["...", "..<"]

    var parameterDescription: RuleConfigurationDescription {
        severityConfiguration
        "lines_look_around" => .integer(linesLookAround)
        "skip_aligned_constants" => .flag(skipAlignedConstants)
        "allowed_no_space_operators" => .list(allowedNoSpaceOperators.map { .string($0) })
    }

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
