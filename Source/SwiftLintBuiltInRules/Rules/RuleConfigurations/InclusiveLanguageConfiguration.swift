import SwiftLintCore

@AutoConfigParser
struct InclusiveLanguageConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = InclusiveLanguageRule

    private static let defaultTerms: Set<String> = [
        "whitelist",
        "blacklist",
        "master",
        "slave",
    ]

    private static let defaultAllowedTerms: Set<String> = [
        "mastercard"
    ]

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "additional_terms")
    private(set) var additionalTerms: Set<String>?
    @ConfigurationElement(key: "override_terms")
    private(set) var overrideTerms: Set<String>?
    @ConfigurationElement(key: "override_allowed_terms")
    private(set) var overrideAllowedTerms: Set<String>?

    var allTerms: [String] {
        let allTerms = overrideTerms ?? Self.defaultTerms
        return allTerms.union(additionalTerms ?? [])
            .map { $0.lowercased() }
            .unique
            .sorted()
    }

    var allAllowedTerms: Set<String> {
        Set((overrideAllowedTerms ?? Self.defaultAllowedTerms).map { $0.lowercased() })
    }
}
