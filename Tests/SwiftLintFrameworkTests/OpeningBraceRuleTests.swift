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
}

private extension Array where Element == Example {
    func removing(_ examples: Self) -> Self {
        filter { !examples.contains($0) }
    }
}
