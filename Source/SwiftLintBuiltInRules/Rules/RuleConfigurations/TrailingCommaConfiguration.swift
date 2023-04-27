struct TrailingCommaConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var mandatoryComma: Bool

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", mandatory_comma: \(mandatoryComma)"
    }

    init(mandatoryComma: Bool = false) {
        self.mandatoryComma = mandatoryComma
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        mandatoryComma = (configuration["mandatory_comma"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
