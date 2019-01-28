import Foundation
import SourceKittenFramework

public struct EmptyParametersRule: ConfigurationProviderRule, SubstitutionCorrectableRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_parameters",
        name: "Empty Parameters",
        description: "Prefer `() -> ` over `Void -> `.",
        kind: .style,
        nonTriggeringExamples: [
            "let abc: () -> Void = {}\n",
            "func foo(completion: () -> Void)\n",
            "func foo(completion: () thows -> Void)\n",
            "let foo: (ConfigurationTests) -> Void throws -> Void)\n",
            "let foo: (ConfigurationTests) ->   Void throws -> Void)\n",
            "let foo: (ConfigurationTests) ->Void throws -> Void)\n"
        ],
        triggeringExamples: [
            "let abc: ↓(Void) -> Void = {}\n",
            "func foo(completion: ↓(Void) -> Void)\n",
            "func foo(completion: ↓(Void) throws -> Void)\n",
            "let foo: ↓(Void) -> () throws -> Void)\n"
        ],
        corrections: [
            "let abc: ↓(Void) -> Void = {}\n": "let abc: () -> Void = {}\n",
            "func foo(completion: ↓(Void) -> Void)\n": "func foo(completion: () -> Void)\n",
            "func foo(completion: ↓(Void) throws -> Void)\n":
                "func foo(completion: () throws -> Void)\n",
            "let foo: ↓(Void) -> () throws -> Void)\n": "let foo: () -> () throws -> Void)\n"
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
        let voidPattern = "\\(Void\\)"
        let pattern = voidPattern + "\\s*(throws\\s+)?->"
        let excludingPattern = "->\\s*" + pattern // excludes curried functions

        return file.match(pattern: pattern,
                          excludingSyntaxKinds: SyntaxKind.commentAndStringKinds,
                          excludingPattern: excludingPattern).compactMap { range in
            let voidRegex = regex(voidPattern)
            return voidRegex.firstMatch(in: file.contents, options: [], range: range)?.range
        }
    }

    public func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        return (violationRange, "()")
    }
}
