import SwiftLintCore

struct InclusiveLanguageConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = InclusiveLanguageRule

    @ConfigurationElement(key: "severity")
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

        if let severityString = configuration[$severityConfiguration.key] {
            try severityConfiguration.apply(configuration: severityString)
        }

        additionalTerms = lowercasedSet(for: $additionalTerms.key, from: configuration)
        overrideTerms = lowercasedSet(for: $overrideTerms.key, from: configuration)
        overrideAllowedTerms = lowercasedSet(for: $overrideAllowedTerms.key, from: configuration)

        var allTerms = overrideTerms ?? defaultTerms
        allTerms.formUnion(additionalTerms ?? [])
        self.allTerms = allTerms.sorted()
        allAllowedTerms = overrideAllowedTerms ?? defaultAllowedTerms
    }

    private func lowercasedSet(for key: String, from config: [String: Any]) -> Set<String>? {
        guard let list = config[key] as? [String] else { return nil }
        return Set(list.map { $0.lowercased() })
    }
}
