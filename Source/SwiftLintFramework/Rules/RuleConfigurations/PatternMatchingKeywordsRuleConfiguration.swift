public struct PatternMatchingKeywordsRuleConfiguration: RuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.warning)
    var maxDeclarations = 1

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", max_declarations: \(maxDeclarations)"
    }

    public init(maxDeclarations: Int) {
        self.maxDeclarations = maxDeclarations
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        maxDeclarations = configuration["max_declarations"] as? Int ?? 1

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
