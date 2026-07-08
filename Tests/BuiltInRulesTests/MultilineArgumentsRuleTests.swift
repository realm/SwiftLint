import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct MultilineArgumentsRuleTests {
    @Test
    func multilineArgumentsWithWithNextLine() {
        let nonTriggeringExamples = #examples([
            "foo()",
            "foo(0)",
            "foo(1, bar: baz) { }",
            "foo(2, bar: baz) {\n}",
            """
                foo(
                    3,
                    bar: baz) { }
                """,
            """
                foo(
                    4, bar: baz) { }
                """,
        ])

        let triggeringExamples = #examples([
            """
                foo(↓1,
                    bar: baz) { }
                """,
        ])

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["first_argument_location": "next_line"])
    }

    @Test
    func multilineArgumentsWithWithSameLine() {
        let nonTriggeringExamples = #examples([
            "foo()",
            "foo(0)",
            "foo(1, bar: 1) { }",
            """
                foo(2, bar: 2) {
                    bar()
                }
                """,
            """
                foo(3,
                    bar: 3) { }
                """,
        ])

        let triggeringExamples = #examples([
            """
                foo(
                    ↓1, ↓bar: baz) { }
                """,
            """
                foo(
                    ↓2,
                    bar: baz) { }
                """,
        ])

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["first_argument_location": "same_line"])
    }

    @Test
    func multilineArgumentsWithOnlyEnforceAfterFirstClosureOnFirstLine() {
        let nonTriggeringExamples = #examples([
            "foo()",
            "foo(0)",
            "foo(1, bar: 1) { }",
            """
                foo(
                    4, bar: baz) { }
                """,
            """
                foo(a: a, b: {
                }, c: {
                })
                """,
            """
                foo(
                    a: a, b: {
                    }, c: {
                })
                """,
            """
                foo(a: a, b: b, c: {
                }, d: {
                })
                """,
            """
                foo(
                    a: a, b: b, c: {
                    }, d: {
                })
                """,
            """
                foo(a: a, b: { [weak self] in
                }, c: { flag in
                })
                """,
        ])

        let triggeringExamples = #examples([
            """
                foo(a: a,
                    b: b, c: {
                })
                """,
            """
                foo(a: a, b: b,
                    c: c, d: {
                    }, d: {
                })
                """,
        ])

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["only_enforce_after_first_closure_on_first_line": true])
    }
}
