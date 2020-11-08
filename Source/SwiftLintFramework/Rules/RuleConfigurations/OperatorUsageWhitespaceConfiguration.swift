public struct OperatorUsageWhitespaceConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var linesLookAround = 2
    private(set) var skipAlignedConstants = true

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription
            + ", lines_look_around: \(linesLookAround)"
            + ", skip_aligned_constants: \(skipAlignedConstants)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        linesLookAround = configuration["lines_look_around"] as? Int ?? 2
        skipAlignedConstants = configuration["skip_aligned_constants"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
