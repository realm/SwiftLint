struct CollectionAlignmentConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = CollectionAlignmentRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var alignColons = false

    init() {}

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", align_colons: \(alignColons)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        alignColons = configuration["align_colons"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
