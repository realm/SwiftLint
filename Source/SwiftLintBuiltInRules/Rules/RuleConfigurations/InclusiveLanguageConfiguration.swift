import SwiftLintCore

private enum ConfigurationKey: String {
    case severity
    case additionalTerms = "additional_terms"
    case overrideTerms = "override_terms"
    case overrideAllowedTerms = "override_allowed_terms"
}

struct InclusiveLanguageConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = InclusiveLanguageRule

    @ConfigurationElement
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "additional_terms")
    private(set) var additionalTerms: Set<String>?
    @ConfigurationElement(key: "override_terms")
    private(set) var overrideTerms: Set<String>?
    @ConfigurationElement(key: "override_allowed_terms")
    private(set) var overrideAllowedTerms: Set<String>?
    private(set) var allTerms: [String]
    private(set) var allAllowedTerms: Set<String>

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
