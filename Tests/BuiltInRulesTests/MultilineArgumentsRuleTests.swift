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
            "foo(\n" +
            "    3,\n" +
            "    bar: baz) { }",
            "foo(\n" +
            "    4, bar: baz) { }",
        ])

        let triggeringExamples = #examples([
            "foo(↓1,\n" +
            "    bar: baz) { }",
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
            "foo(2, bar: 2) {\n" +
            "    bar()\n" +
            "}",
            "foo(3,\n" +
            "    bar: 3) { }",
        ])

        let triggeringExamples = #examples([
            "foo(\n" +
            "    ↓1, ↓bar: baz) { }",
            "foo(\n" +
            "    ↓2,\n" +
            "    bar: baz) { }",
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
            "foo(\n" +
            "    4, bar: baz) { }",
            "foo(a: a, b: {\n" +
            "}, c: {\n" +
            "})",
            "foo(\n" +
            "    a: a, b: {\n" +
            "    }, c: {\n" +
            "})",
            "foo(a: a, b: b, c: {\n" +
            "}, d: {\n" +
            "})",
            "foo(\n" +
            "    a: a, b: b, c: {\n" +
            "    }, d: {\n" +
            "})",
            "foo(a: a, b: { [weak self] in\n" +
            "}, c: { flag in\n" +
            "})",
        ])

        let triggeringExamples = #examples([
            "foo(a: a,\n" +
            "    b: b, c: {\n" +
            "})",
            "foo(a: a, b: b,\n" +
            "    c: c, d: {\n" +
            "    }, d: {\n" +
            "})",
        ])

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["only_enforce_after_first_closure_on_first_line": true])
    }
}
