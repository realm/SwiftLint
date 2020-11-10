import Foundation
import SourceKittenFramework

public struct InclusiveLanguageRule: ASTRule, ConfigurationProviderRule {
    public var configuration = InclusiveLanguageConfiguration()

    private let declarationCharacterSet = CharacterSet.alphanumerics
        .union(CharacterSet(charactersIn: "_"))

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

        let components = name.components(separatedBy: declarationCharacterSet.inverted)
            .flatMap { $0.componentsSeparateByCamelOrSnakeCase }
            .map { $0.lowercased() }
        guard let term = configuration.allTerms.intersection(components).first else {
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

private extension String {
    var componentsSeparateByCamelOrSnakeCase: [String] {
        if contains("_" as Character) {
            return components(separatedBy: "_")
        } else {
            return componentsSeparatedByCamelCase
        }
    }
}
