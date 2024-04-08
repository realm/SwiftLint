@testable import SwiftLintBuiltInRules

class OpeningBraceRuleTests: SwiftLintTestCase {
    func testDefaultExamplesRunInMultilineFuncMode() {
        let description = OpeningBraceRule.description
            .with(triggeringExamples: OpeningBraceRule.description.triggeringExamples.removing([
                Example("func abc(a: A,\n\tb: B)\n↓{"),
                Example("""
                    internal static func getPointer()
                      -> UnsafeMutablePointer<_ThreadLocalStorage>
                    ↓{
                        return _swift_stdlib_threadLocalStorageGet().assumingMemoryBound(
                            to: _ThreadLocalStorage.self)
                    }
                    """)
            ]))

        verifyRule(description, ruleConfiguration: ["allow_multiline_func": true])
    }

    // swiftlint:disable:next function_body_length
    func testWithAllowMultilineFuncTrue() {
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
                """)
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
                """)
        ]

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["allow_multiline_func": true])
    }

    func testWithIgnoreMultilineConditionStatementsTrue() {
        let nonTriggeringExamples = OpeningBraceRule.description.nonTriggeringExamples + [
            Example("""
                if x,
                   y
                {

                } else if z,
                          w
                {

                }
                """),
            Example("""
                while
                    x,
                    y
                {}
                """)
        ]

        let triggeringExamples = [
            Example("""
                if x, y
                {

                }
                """),
            Example("""
                if
                    x,
                    y
                {

                } else if z
                {

                }
                """),
            Example("""
                while x, y
                {}
                """)
        ]

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["ignore_multiline_condition_statements": true])
    }
}

private extension Array where Element == Example {
    func removing(_ examples: Self) -> Self {
        filter { !examples.contains($0) }
    }
}
