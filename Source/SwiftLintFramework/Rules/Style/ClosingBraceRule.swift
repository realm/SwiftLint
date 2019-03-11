import Foundation
import SourceKittenFramework

public struct ClosingBraceRule: SubstitutionCorrectableRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closing_brace",
        name: "Closing Brace Spacing",
        description: "Closing brace with closing parenthesis " +
                     "should not have any whitespaces in the middle.",
        kind: .style,
        nonTriggeringExamples: [
            "[].map({ })",
            "[].map(\n  { }\n)"
        ],
        triggeringExamples: [
            "[].map({ ↓} )",
            "[].map({ ↓}\t)"
        ],
        corrections: [
            "[].map({ ↓} )\n": "[].map({ })\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: File) -> [NSRange] {
        return file.match(pattern: "(\\}[ \\t]+\\))", excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }

    public func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        return (violationRange, "})")
    }
}
