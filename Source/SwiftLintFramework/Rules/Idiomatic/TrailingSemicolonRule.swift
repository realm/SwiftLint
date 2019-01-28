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
        nonTriggeringExamples: [ "let a = 0\n" ],
        triggeringExamples: [
            "let a = 0↓;\n",
            "let a = 0↓;\nlet b = 1\n",
            "let a = 0↓;;\n",
            "let a = 0↓;    ;;\n",
            "let a = 0↓; ; ;\n"
        ],
        corrections: [
            "let a = 0↓;\n": "let a = 0\n",
            "let a = 0↓;\nlet b = 1\n": "let a = 0\nlet b = 1\n",
            "let a = 0↓;;\n": "let a = 0\n",
            "let a = 0↓;    ;;\n": "let a = 0\n",
            "let a = 0↓; ; ;\n": "let a = 0\n"
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
        return file.match(pattern: "(;+([^\\S\\n]?)*)+;?$",
                          excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
    }

    public func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        return (violationRange, "")
    }
}
