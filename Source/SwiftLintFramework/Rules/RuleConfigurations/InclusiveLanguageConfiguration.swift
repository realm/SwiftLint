private enum ConfigurationKey: String {
    case severity
    case additionalTerms = "additional_terms"
    case overrideTerms = "override_terms"
    case overrideAllowedTerms = "override_allowed_terms"
}

public struct InclusiveLanguageConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public var severityConfiguration = SeverityConfiguration(.warning)
    public var additionalTerms: Set<String>?
    public var overrideTerms: Set<String>?
    public var overrideAllowedTerms: Set<String>?
    public var allTerms: Set<String>
    public var allAllowedTerms: Set<String>

    public var consoleDescription: String {
        severityConfiguration.consoleDescription
            + ", additional_terms: \(additionalTerms?.sorted() ?? [])"
            + ", override_terms: \(overrideTerms?.sorted() ?? [])"
            + ", override_allowed_terms: \(overrideAllowedTerms?.sorted() ?? [])"
    }

    private let defaultTerms: Set<String> = [
        "whitelist",
        "blacklist",
        "master",
        "slave"
    ]

    private let defaultAllowedTerms: Set<String> = [
        "mastercard"
    ]

    public init() {
        self.allTerms = defaultTerms
        self.allAllowedTerms = defaultAllowedTerms
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] {
            try severityConfiguration.apply(configuration: severityString)
        }

        additionalTerms = lowercasedSet(for: .additionalTerms, from: configuration)
        overrideTerms = lowercasedSet(for: .overrideTerms, from: configuration)
        overrideAllowedTerms = lowercasedSet(for: .overrideAllowedTerms, from: configuration)

        allTerms = overrideTerms ?? defaultTerms
        allTerms.formUnion(additionalTerms ?? [])
        allAllowedTerms = overrideAllowedTerms ?? defaultAllowedTerms
    }

    private func lowercasedSet(for key: ConfigurationKey, from config: [String: Any]) -> Set<String>? {
        guard let list = config[key.rawValue] as? [String] else { return nil }
        return Set(list.map { $0.lowercased() })
    }
}
