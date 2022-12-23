import Foundation
import SourceKittenFramework

struct VoidReturnRule: ConfigurationProviderRule, SubstitutionCorrectableRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "void_return",
        name: "Void Return",
        description: "Prefer `-> Void` over `-> ()`",
        kind: .style,
        nonTriggeringExamples: [
            Example("let abc: () -> Void = {}\n"),
            Example("let abc: () -> (VoidVoid) = {}\n"),
            Example("func foo(completion: () -> Void)\n"),
            Example("let foo: (ConfigurationTests) -> () throws -> Void\n"),
            Example("let foo: (ConfigurationTests) ->   () throws -> Void\n"),
            Example("let foo: (ConfigurationTests) ->() throws -> Void\n"),
            Example("let foo: (ConfigurationTests) -> () -> Void\n")
        ],
        triggeringExamples: [
            Example("let abc: () -> ↓() = {}\n"),
            Example("let abc: () -> ↓(Void) = {}\n"),
            Example("let abc: () -> ↓(   Void ) = {}\n"),
            Example("func foo(completion: () -> ↓())\n"),
            Example("func foo(completion: () -> ↓(   ))\n"),
            Example("func foo(completion: () -> ↓(Void))\n"),
            Example("let foo: (ConfigurationTests) -> () throws -> ↓()\n")
        ],
        corrections: [
            Example("let abc: () -> ↓() = {}\n"): Example("let abc: () -> Void = {}\n"),
            Example("let abc: () -> ↓(Void) = {}\n"): Example("let abc: () -> Void = {}\n"),
            Example("let abc: () -> ↓(   Void ) = {}\n"): Example("let abc: () -> Void = {}\n"),
            Example("func foo(completion: () -> ↓())\n"): Example("func foo(completion: () -> Void)\n"),
            Example("func foo(completion: () -> ↓(   ))\n"): Example("func foo(completion: () -> Void)\n"),
            Example("func foo(completion: () -> ↓(Void))\n"): Example("func foo(completion: () -> Void)\n"),
            Example("let foo: (ConfigurationTests) -> () throws -> ↓()\n"):
                Example("let foo: (ConfigurationTests) -> () throws -> Void\n")
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let kinds = SyntaxKind.commentAndStringKinds
        let parensPattern = "\\(\\s*(?:Void)?\\s*\\)"
        let pattern = "->\\s*\(parensPattern)\\s*(?!->)"
        let excludingPattern = "(\(pattern))\\s*(throws\\s+)?->"

        return file.match(pattern: pattern, excludingSyntaxKinds: kinds, excludingPattern: excludingPattern,
                          exclusionMapping: { $0.range(at: 1) }).compactMap {
            let parensRegex = regex(parensPattern)
            return parensRegex.firstMatch(in: file.contents, options: [], range: $0)?.range
        }
    }

    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "Void")
    }
}
