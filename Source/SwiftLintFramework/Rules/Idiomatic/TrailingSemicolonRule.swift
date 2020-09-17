import Foundation
import SourceKittenFramework

public struct TrailingSemicolonRule: SubstitutionCorrectableRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_semicolon",
        name: "Trailing Semicolon",
        description: "Lines should not have trailing semicolons.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let a = 0\n"),
            Example("let a = 0; let b = 0")
        ],
        triggeringExamples: [
            Example("let a = 0↓;\n"),
            Example("let a = 0↓;\nlet b = 1\n")
        ],
        corrections: [
            Example("let a = 0↓;\n"): Example("let a = 0\n"),
            Example("let a = 0↓;\nlet b = 1\n"): Example("let a = 0\nlet b = 1\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return file.match(pattern: "(;+([^\\S\\n]?)*)+;?$",
                          excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }
}
