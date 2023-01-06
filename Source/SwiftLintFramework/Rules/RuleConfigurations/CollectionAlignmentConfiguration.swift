struct CollectionAlignmentConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var alignColons = false

    init() {}

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", align_colons: \(alignColons)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        alignColons = configuration["align_colons"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
