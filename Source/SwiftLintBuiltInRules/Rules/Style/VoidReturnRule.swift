import Foundation
import SourceKittenFramework

struct VoidReturnRule: SubstitutionCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "void_return",
        name: "Void Return",
        description: "Prefer `-> Void` over `-> ()`",
        kind: .style,
        nonTriggeringExamples: [
            Example("let abc: () -> Void = {}"),
            Example("let abc: () -> (VoidVoid) = {}"),
            Example("func foo(completion: () -> Void)"),
            Example("let foo: (ConfigurationTests) -> () throws -> Void"),
            Example("let foo: (ConfigurationTests) ->   () throws -> Void"),
            Example("let foo: (ConfigurationTests) ->() throws -> Void"),
            Example("let foo: (ConfigurationTests) -> () -> Void"),
            Example("let foo: () -> () async -> Void"),
            Example("let foo: () -> () async throws -> Void"),
            Example("let foo: () -> () async -> Void"),
            Example("func foo() -> () async throws -> Void {}"),
            Example("func foo() async throws -> () async -> Void { return {} }")
        ],
        triggeringExamples: [
            Example("let abc: () -> ↓() = {}"),
            Example("let abc: () -> ↓(Void) = {}"),
            Example("let abc: () -> ↓(   Void ) = {}"),
            Example("func foo(completion: () -> ↓())"),
            Example("func foo(completion: () -> ↓(   ))"),
            Example("func foo(completion: () -> ↓(Void))"),
            Example("let foo: (ConfigurationTests) -> () throws -> ↓()"),
            Example("func foo() async -> ↓()"),
            Example("func foo() async throws -> ↓()")
        ],
        corrections: [
            Example("let abc: () -> ↓() = {}"): Example("let abc: () -> Void = {}"),
            Example("let abc: () -> ↓(Void) = {}"): Example("let abc: () -> Void = {}"),
            Example("let abc: () -> ↓(   Void ) = {}"): Example("let abc: () -> Void = {}"),
            Example("func foo(completion: () -> ↓())"): Example("func foo(completion: () -> Void)"),
            Example("func foo(completion: () -> ↓(   ))"): Example("func foo(completion: () -> Void)"),
            Example("func foo(completion: () -> ↓(Void))"): Example("func foo(completion: () -> Void)"),
            Example("let foo: (ConfigurationTests) -> () throws -> ↓()"):
                Example("let foo: (ConfigurationTests) -> () throws -> Void"),
            Example("func foo() async throws -> ↓()"): Example("func foo() async throws -> Void")
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
        let excludingPattern = "(\(pattern))\\s*(async\\s+)?(throws\\s+)?->"

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
