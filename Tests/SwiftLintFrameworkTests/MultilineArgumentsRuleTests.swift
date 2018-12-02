import SwiftLintFramework
import XCTest

class MultilineArgumentsRuleTests: XCTestCase {
    func testMultilineArgumentsWithDefaultConfiguration() {
        verifyRule(MultilineArgumentsRule.description)
    }

    func testMultilineArgumentsWithWithNextLine() {
        let nonTriggeringExamples = [
            "foo()",
            "foo(0)",
            "foo(1, bar: baz) { }",
            "foo(2, bar: baz) {\n}",
            "foo(\n" +
            "    3,\n" +
            "    bar: baz) { }",
            "foo(\n" +
            "    4, bar: baz) { }"
        ]

        let triggeringExamples = [
            "foo(↓1,\n" +
            "    bar: baz) { }"
        ]

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["first_argument_location": "next_line"])
    }

    func testMultilineArgumentsWithWithSameLine() {
        let nonTriggeringExamples = [
            "foo()",
            "foo(0)",
            "foo(1, bar: 1) { }",
            "foo(2, bar: 2) {\n" +
            "    bar()\n" +
            "}",
            "foo(3,\n" +
            "    bar: 3) { }"
        ]

        let triggeringExamples = [
            "foo(\n" +
            "    ↓1, ↓bar: baz) { }",
            "foo(\n" +
            "    ↓2,\n" +
            "    bar: baz) { }"
        ]

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["first_argument_location": "same_line"])
    }

    func testMultilineArgumentsWithOnlyEnforceAfterFirstClosureOnFirstLine() {
        let nonTriggeringExamples: [String] = [
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
            "})"
        ]

        let triggeringExamples = [
            "foo(a: a,\n" +
            "    b: b, c: {\n" +
            "})",
            "foo(a: a, b: b,\n" +
            "    c: c, d: {\n" +
            "    }, d: {\n" +
            "})"
        ]

        let description = MultilineArgumentsRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["only_enforce_after_first_closure_on_first_line": true])
    }
}
