import Foundation
import SourceKittenFramework

public struct VoidReturnRule: ConfigurationProviderRule, SubstitutionCorrectableRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "void_return",
        name: "Void Return",
        description: "Prefer `-> Void` over `-> ()`.",
        kind: .style,
        nonTriggeringExamples: [
            "let abc: () -> Void = {}\n",
            "let abc: () -> (VoidVoid) = {}\n",
            "func foo(completion: () -> Void)\n",
            "let foo: (ConfigurationTests) -> () throws -> Void)\n",
            "let foo: (ConfigurationTests) ->   () throws -> Void)\n",
            "let foo: (ConfigurationTests) ->() throws -> Void)\n",
            "let foo: (ConfigurationTests) -> () -> Void)\n"
        ],
        triggeringExamples: [
            "let abc: () -> ↓() = {}\n",
            "let abc: () -> ↓(Void) = {}\n",
            "let abc: () -> ↓(   Void ) = {}\n",
            "func foo(completion: () -> ↓())\n",
            "func foo(completion: () -> ↓(   ))\n",
            "func foo(completion: () -> ↓(Void))\n",
            "let foo: (ConfigurationTests) -> () throws -> ↓())\n"
        ],
        corrections: [
            "let abc: () -> ↓() = {}\n": "let abc: () -> Void = {}\n",
            "let abc: () -> ↓(Void) = {}\n": "let abc: () -> Void = {}\n",
            "let abc: () -> ↓(   Void ) = {}\n": "let abc: () -> Void = {}\n",
            "func foo(completion: () -> ↓())\n": "func foo(completion: () -> Void)\n",
            "func foo(completion: () -> ↓(   ))\n": "func foo(completion: () -> Void)\n",
            "func foo(completion: () -> ↓(Void))\n": "func foo(completion: () -> Void)\n",
            "let foo: (ConfigurationTests) -> () throws -> ↓())\n":
                "let foo: (ConfigurationTests) -> () throws -> Void)\n"
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

    public func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        return (violationRange, "Void")
    }
}
