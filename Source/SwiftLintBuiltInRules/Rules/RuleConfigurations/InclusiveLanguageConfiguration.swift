import SwiftLintCore

@AutoConfigParser
struct InclusiveLanguageConfiguration: SeverityBasedRuleConfiguration {
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

    /// All terms to check for, lowercased and sorted. Precomputed once per configuration since deriving the list is
    /// too expensive to repeat for every linted file.
    private(set) var allTerms = Self.computeAllTerms(overrideTerms: nil, additionalTerms: nil)

    /// All allowed terms, lowercased. Precomputed once per configuration.
    private(set) var allAllowedTerms = Self.computeAllAllowedTerms(overrideAllowedTerms: nil)

    // swiftlint:disable:next unneeded_throws_rethrows
    mutating func validate() throws(Issue) {
        allTerms = Self.computeAllTerms(overrideTerms: overrideTerms, additionalTerms: additionalTerms)
        allAllowedTerms = Self.computeAllAllowedTerms(overrideAllowedTerms: overrideAllowedTerms)
    }

    private static func computeAllTerms(overrideTerms: Set<String>?, additionalTerms: Set<String>?) -> [String] {
        (overrideTerms ?? defaultTerms).union(additionalTerms ?? [])
            .map { $0.lowercased() }
            .unique
            .sorted()
    }

    private static func computeAllAllowedTerms(overrideAllowedTerms: Set<String>?) -> Set<String> {
        Set((overrideAllowedTerms ?? defaultAllowedTerms).map { $0.lowercased() })
    }
}
