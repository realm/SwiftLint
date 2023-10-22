@testable import SwiftLintBuiltInRules

class ExplicitInitRuleTests: SwiftLintTestCase {
    func testIncludeBareInit() {
        let nonTriggeringExamples = [
            Example("let foo = Foo()"),
            Example("let foo = init()")
        ] + ExplicitInitRule.description.nonTriggeringExamples

        let triggeringExamples = [
            Example("let foo: Foo = ↓.init()"),
            Example("let foo: [Foo] = [↓.init(), ↓.init()]"),
            Example("foo(↓.init())")
        ]

        var correction = [
            Example("""
            f { e in
                A↓.init(e: e)
            }
            """):
                Example("""
                f { e in
                    A(e: e)
                }
                """)
        ]
        correction.merge(ExplicitInitRule.description.corrections) { current, _ in current }

        let description = ExplicitInitRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: correction)

        verifyRule(description, ruleConfiguration: ["include_bare_init": true])
    }
}
