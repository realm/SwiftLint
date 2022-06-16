private enum ConfigurationKey: String {
    case severity
    case additionalTerms = "additional_terms"
    case overrideTerms = "override_terms"
    case overrideAllowedTerms = "override_allowed_terms"
}

struct InclusiveLanguageConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = InclusiveLanguageRule

    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private var additionalTerms: Set<String>?
    private var overrideTerms: Set<String>?
    private var overrideAllowedTerms: Set<String>?
    private(set) var allTerms: [String]
    private(set) var allAllowedTerms: Set<String>

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "additional_terms" => .list(additionalTerms?.sorted().map { .string($0) } ?? [])
        "override_terms" => .list(overrideTerms?.sorted().map { .string($0) } ?? [])
        "override_allowed_terms" => .list(overrideAllowedTerms?.sorted().map { .string($0) } ?? [])
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

    init() {
        self.allTerms = defaultTerms.sorted()
        self.allAllowedTerms = defaultAllowedTerms
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] {
            try severityConfiguration.apply(configuration: severityString)
        }

        additionalTerms = lowercasedSet(for: .additionalTerms, from: configuration)
        overrideTerms = lowercasedSet(for: .overrideTerms, from: configuration)
        overrideAllowedTerms = lowercasedSet(for: .overrideAllowedTerms, from: configuration)

        var allTerms = overrideTerms ?? defaultTerms
        allTerms.formUnion(additionalTerms ?? [])
        self.allTerms = allTerms.sorted()
        allAllowedTerms = overrideAllowedTerms ?? defaultAllowedTerms
    }

    private func lowercasedSet(for key: ConfigurationKey, from config: [String: Any]) -> Set<String>? {
        guard let list = config[key.rawValue] as? [String] else { return nil }
        return Set(list.map { $0.lowercased() })
    }
}
