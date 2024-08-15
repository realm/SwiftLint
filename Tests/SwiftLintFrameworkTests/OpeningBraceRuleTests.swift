@testable import SwiftLintBuiltInRules

final class OpeningBraceRuleTests: SwiftLintTestCase {
    func testDefaultExamplesRunInMultilineMode() {
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
                    """),
            ]))

        verifyRule(description, ruleConfiguration: ["allow_multiline_func": true])
    }

    // swiftlint:disable:next function_body_length
    func testWithAllowMultilineTrue() {
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
        ]

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["allow_multiline_func": true])
    }

    func testWithIgnoreMultilineTypeHeadersTrue() {
        let nonTriggeringExamples = [
            Example("""
                extension A
                    where B: Equatable
                {}
                """),
            Example("""
                struct S {
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
                """)
        ]

        let triggeringExamples = [
            Example("""
                if x
                {}
                """),
            Example("""
                if x {

                } else if y, z
                {}
                """),
            Example("""
                if x {

                } else
                {}
                """),
        ]

        let description = OpeningBraceRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["ignore_multiline_statement_conditions": true])
    }
}

private extension Array where Element == Example {
    func removing(_ examples: Self) -> Self {
        filter { !examples.contains($0) }
    }
}
