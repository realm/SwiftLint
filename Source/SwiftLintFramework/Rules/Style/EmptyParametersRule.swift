import Foundation
import SourceKittenFramework

public struct EmptyParametersRule: ConfigurationProviderRule, SubstitutionCorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_parameters",
        name: "Empty Parameters",
        description: "Prefer `() -> ` over `Void -> `.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let abc: () -> Void = {}\n"),
            Example("func foo(completion: () -> Void)\n"),
            Example("func foo(completion: () thows -> Void)\n"),
            Example("let foo: (ConfigurationTests) -> Void throws -> Void)\n"),
            Example("let foo: (ConfigurationTests) ->   Void throws -> Void)\n"),
            Example("let foo: (ConfigurationTests) ->Void throws -> Void)\n")
        ],
        triggeringExamples: [
            Example("let abc: ↓(Void) -> Void = {}\n"),
            Example("func foo(completion: ↓(Void) -> Void)\n"),
            Example("func foo(completion: ↓(Void) throws -> Void)\n"),
            Example("let foo: ↓(Void) -> () throws -> Void)\n")
        ],
        corrections: [
            Example("let abc: ↓(Void) -> Void = {}\n"): Example("let abc: () -> Void = {}\n"),
            Example("func foo(completion: ↓(Void) -> Void)\n"): Example("func foo(completion: () -> Void)\n"),
            Example("func foo(completion: ↓(Void) throws -> Void)\n"):
                Example("func foo(completion: () throws -> Void)\n"),
            Example("let foo: ↓(Void) -> () throws -> Void)\n"): Example("let foo: () -> () throws -> Void)\n")
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

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "()")
    }
}
