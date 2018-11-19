public struct CollectionAlignmentConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var alignColons = false

    init() {}

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", align_colons: \(alignColons)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        alignColons = configuration["align_colons"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
