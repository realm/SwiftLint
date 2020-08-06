import SourceKittenFramework

public struct InclusiveLanguageRule: ASTRule, ConfigurationProviderRule {
    public var configuration = InclusiveLanguageConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "inclusive_language",
        name: "Inclusive Language",
        description: "Identifiers should use inclusive language that avoids"
            + " discrimination against groups of people based on race, gender, or socioeconomic status",
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
        guard let term = configuration.allTerms.first(where: { lowercased.contains($0) })
            else { return [] }

        let reason = "Declaration \(name) contains the term \"\(term)\" which is not considered inclusive."
        let violation = StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file, byteOffset: nameByteRange.location),
            reason: reason
        )
        return [violation]
    }
}
