@testable import SwiftLintFramework

class MultilineArgumentsRuleTests: SwiftLintTestCase {
    func testMultilineArgumentsWithWithNextLine() {
        let nonTriggeringExamples = [
            Example("foo()"),
            Example("foo(0)"),
            Example("foo(1, bar: baz) { }"),
            Example("foo(2, bar: baz) {\n}"),
            Example("foo(\n" +
            "    3,\n" +
            "    bar: baz) { }"),
            Example("foo(\n" +
            "    4, bar: baz) { }")
        ]

        let triggeringExamples = [
            Example("foo(↓1,\n" +
            "    bar: baz) { }")
        ]

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["first_argument_location": "next_line"])
    }

    func testMultilineArgumentsWithWithSameLine() {
        let nonTriggeringExamples = [
            Example("foo()"),
            Example("foo(0)"),
            Example("foo(1, bar: 1) { }"),
            Example("foo(2, bar: 2) {\n" +
            "    bar()\n" +
            "}"),
            Example("foo(3,\n" +
            "    bar: 3) { }")
        ]

        let triggeringExamples = [
            Example("foo(\n" +
            "    ↓1, ↓bar: baz) { }"),
            Example("foo(\n" +
            "    ↓2,\n" +
            "    bar: baz) { }")
        ]

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["first_argument_location": "same_line"])
    }

    func testMultilineArgumentsWithOnlyEnforceAfterFirstClosureOnFirstLine() {
        let nonTriggeringExamples: [Example] = [
            Example("foo()"),
            Example("foo(0)"),
            Example("foo(1, bar: 1) { }"),
            Example("foo(\n" +
            "    4, bar: baz) { }"),
            Example("foo(a: a, b: {\n" +
            "}, c: {\n" +
            "})"),
            Example("foo(\n" +
            "    a: a, b: {\n" +
            "    }, c: {\n" +
            "})"),
            Example("foo(a: a, b: b, c: {\n" +
            "}, d: {\n" +
            "})"),
            Example("foo(\n" +
            "    a: a, b: b, c: {\n" +
            "    }, d: {\n" +
            "})"),
            Example("foo(a: a, b: { [weak self] in\n" +
            "}, c: { flag in\n" +
            "})")
        ]

        let triggeringExamples = [
            Example("foo(a: a,\n" +
            "    b: b, c: {\n" +
            "})"),
            Example("foo(a: a, b: b,\n" +
            "    c: c, d: {\n" +
            "    }, d: {\n" +
            "})")
        ]

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["only_enforce_after_first_closure_on_first_line": true])
    }
}
