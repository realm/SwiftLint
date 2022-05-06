import SourceKittenFramework

public struct InclusiveLanguageRule: ASTRule, ConfigurationProviderRule {
    public var configuration = InclusiveLanguageConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "inclusive_language",
        name: "Inclusive Language",
        description: """
            Identifiers should use inclusive language that avoids discrimination against groups of people based on \
            race, gender, or socioeconomic status
            """,
        kind: .style,
        nonTriggeringExamples: InclusiveLanguageRuleExamples.nonTriggeringExamples,
        triggeringExamples: InclusiveLanguageRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind != .varParameter, // Will be caught by function declaration
            let name = dictionary.name,
            let nameByteRange = dictionary.nameByteRange
            else { return [] }

        let lowercased = name.lowercased()
        let sortedTerms = configuration.allTerms.sorted()
        let violationTerm = sortedTerms.first { term in
            guard let range = lowercased.range(of: term) else { return false }
            let overlapsAllowedTerm = configuration.allAllowedTerms.contains { allowedTerm in
                guard let allowedRange = lowercased.range(of: allowedTerm) else { return false }
                return range.overlaps(allowedRange)
            }
            return !overlapsAllowedTerm
        }

        guard let term = violationTerm else {
            return []
        }

        return [
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, byteOffset: nameByteRange.location),
                reason: "Declaration \(name) contains the term \"\(term)\" which is not considered inclusive."
            )
        ]
    }
}
