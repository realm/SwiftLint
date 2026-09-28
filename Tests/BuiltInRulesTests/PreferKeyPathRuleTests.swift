import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct PreferKeyPathRuleTests {
    private static let extendedMode = ["restrict_to_standard_functions": false]
    private static let ignoreIdentity = ["ignore_identity_closures": true]
    private static let extendedModeAndIgnoreIdentity = [
        "restrict_to_standard_functions": false,
        "ignore_identity_closures": true,
    ]

    @Test(.disabled(if: SwiftVersion.current < .six))
    func identityExpressionInSwift6() {
        let description = PreferKeyPathRule.description
            .with(nonTriggeringExamples: #examples([
                "f.filter { a in b }",
                "f.g { $1 }".asExample(configuration: Self.extendedMode),
                "f { $0 }".asExample(configuration: Self.extendedModeAndIgnoreIdentity),
                "f.map { $0 }".asExample(configuration: Self.ignoreIdentity),
            ]))
            .with(triggeringExamples: #examples([
                "f.compactMap ↓{ $0 }",
                "f.map ↓{ a in a }",
                "f.g { $0 }".asExample(configuration: Self.extendedMode),
            ]))
            .with(corrections: #corrections([
                "f.map ↓{ $0 }":
                    "f.map(\\.self)",
                "f.g { $0 }".asExample(configuration: Self.extendedMode):
                    "f.g(\\.self)",
                "f { $0 }"
                    .asExample(configuration: Self.extendedModeAndIgnoreIdentity): // no change with option enabled
                    "f { $0 }",
                "f.map { $0 }".asExample(configuration: Self.ignoreIdentity): // no change with option enabled
                    "f.map { $0 }",
            ]))

        verifyRule(description)
    }

    @Test
    func closureNestedInMacroExpansionIsNotRewritten() {
        // A closure that is a direct macro argument (e.g. `#Predicate { $0.a }`) is already
        // covered by the rule's own nonTriggeringExamples. This covers a closure nested one or
        // more levels deeper inside a macro expansion's arguments, such as a standard-function
        // call passed to `#require`/`#expect`. Rewriting it to a key path can produce code that
        // fails to compile, since these macros decompose the call in a way that loses its
        // non-throwing guarantee.
        let description = PreferKeyPathRule.description
            .with(nonTriggeringExamples: #examples([
                "#require(f.first(where: { $0.a }))",
                "#expect(f.first(where: { $0.a }) != nil)",
                "#require(g(f.first(where: { $0.a })))",
            ]))
            .with(corrections: #corrections([
                "#require(f.first(where: { $0.a }))": // no change: nested inside a macro expansion
                    "#require(f.first(where: { $0.a }))",
            ]))

        verifyRule(description)
    }
}
