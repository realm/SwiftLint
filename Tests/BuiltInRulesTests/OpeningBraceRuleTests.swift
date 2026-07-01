import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct OpeningBraceRuleTests {
    @Test
    func defaultNonTriggeringExamplesWithMultilineOptionsTrue() {
        let description = OpeningBraceRule.description
            .with(triggeringExamples: [])
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: [
            "ignore_multiline_statement_conditions": true,
            "ignore_multiline_type_headers": true,
            "ignore_multiline_function_signatures": true,
        ])
    }

    @Test
    func withIgnoreMultilineTypeHeadersTrue() {
        let nonTriggeringExamples = #examples([
            """
                extension A
                    where B: Equatable
                {}
                """,
            """
                struct S: Comparable,
                          Identifiable
                {
                    init() {}
                }
                """,
        ])

        let triggeringExamples = #examples([
            """
                struct S
                ↓{}
                """,
            """
                extension A where B: Equatable
                ↓{

                }
                """,
            """
                class C
                    // with comments
                ↓{}
                """,
        ])

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["ignore_multiline_type_headers": true])
    }

    @Test
    func withIgnoreMultilineStatementConditionsTrue() {
        let nonTriggeringExamples = #examples([
            """
                while
                    abc
                {}
                """,
            """
                if x {

                } else if
                    y,
                    z
                {

                }
                """,
            """
                if
                    condition1,
                    let var1 = var1
                {}
                """,
        ])

        let triggeringExamples = #examples([
            """
                if x
                ↓{}
                """,
            """
                if x {

                } else if y, z
                ↓{}
                """,
            """
                if x {

                } else
                ↓{}
                """,
            """
                while abc
                    // comments
                ↓{
                }
                """,
        ])

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["ignore_multiline_statement_conditions": true])
    }

    @Test
    func withIgnoreMultilineFunctionSignaturesTrue() { // swiftlint:disable:this function_body_length
        let nonTriggeringExamples = #examples([
            """
                func abc(
                )
                {}
                """,
            """
                func abc(a: Int,
                         b: Int)

                {

                }
                """,
            """
                struct S {
                    init(
                    )
                    {}
                }
                """,
            """
                class C {
                    init(a: Int,
                         b: Int)

                  {

                    }
                }
                """,
        ])

        let triggeringExamples = #examples([
            """
                func abc()
                ↓{}
                """,
            """
                func abc(a: Int,        b: Int)

                ↓{

                }
                """,
            """
                struct S {
                    init()
                    ↓{}
                }
                """,
            """
                class C {
                    init(a: Int,       b: Int)

                            ↓{

                    }
                }
                """,
            """
                class C {
                    init(a: Int)
                        // with comments
                    ↓{}
                }
                """,
        ])

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["ignore_multiline_function_signatures": true])
    }
}
