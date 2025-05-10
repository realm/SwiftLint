@testable import SwiftLintBuiltInRules
import TestHelpers

final class OpeningBraceRuleTests: SwiftLintTestCase {
    func testDefaultNonTriggeringExamplesWithMultilineOptionsTrue() {
        let description = OpeningBraceRule.description
            .with(triggeringExamples: [])
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: [
            "ignore_multiline_statement_conditions": true,
            "ignore_multiline_type_headers": true,
            "ignore_multiline_function_signatures": true,
        ])
    }

    func testWithIgnoreMultilineTypeHeadersTrue() {
        let nonTriggeringExamples = [
            Example("""
                extension A
                    where B: Equatable
                {}
                """),
            Example("""
                struct S: Comparable,
                          Identifiable
                {
                    init() {}
                }
                """),
        ]

        let triggeringExamples = [
            Example("""
                struct S
                ↓{}
                """),
            Example("""
                extension A where B: Equatable
                ↓{

                }
                """),
            Example("""
                class C
                    // with comments
                ↓{}
                """),
        ]

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["ignore_multiline_type_headers": true])
    }

    func testWithIgnoreMultilineStatementConditionsTrue() {
        let nonTriggeringExamples = [
            Example("""
                while
                    abc
                {}
                """),
            Example("""
                if x {

                } else if
                    y,
                    z
                {

                }
                """),
            Example("""
                if
                    condition1,
                    let var1 = var1
                {}
                """),
        ]

        let triggeringExamples = [
            Example("""
                if x
                ↓{}
                """),
            Example("""
                if x {

                } else if y, z
                ↓{}
                """),
            Example("""
                if x {

                } else
                ↓{}
                """),
            Example("""
                while abc
                    // comments
                ↓{
                }
                """),
        ]

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["ignore_multiline_statement_conditions": true])
    }

    // swiftlint:disable:next function_body_length
    func testWithIgnoreMultilineFunctionSignaturesTrue() {
        let nonTriggeringExamples = [
            Example("""
                func abc(
                )
                {}
                """),
            Example("""
                func abc(a: Int,
                         b: Int)

                {

                }
                """),
            Example("""
                struct S {
                    init(
                    )
                    {}
                }
                """),
            Example("""
                class C {
                    init(a: Int,
                         b: Int)

                  {

                    }
                }
                """),
        ]

        let triggeringExamples = [
            Example("""
                func abc()
                ↓{}
                """),
            Example("""
                func abc(a: Int,        b: Int)

                ↓{

                }
                """),
            Example("""
                struct S {
                    init()
                    ↓{}
                }
                """),
            Example("""
                class C {
                    init(a: Int,       b: Int)

                            ↓{

                    }
                }
                """),
            Example("""
                class C {
                    init(a: Int)
                        // with comments
                    ↓{}
                }
                """),
        ]

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["ignore_multiline_function_signatures": true])
    }
}

private extension Array where Element == Example {
    func removing(_ examples: Self) -> Self {
        filter { !examples.contains($0) }
    }
}
