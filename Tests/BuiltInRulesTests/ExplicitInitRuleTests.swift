import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ExplicitInitRuleTests {
    @Test
    func includeBareInit() {
        let nonTriggeringExamples = #examples([
            "let foo = Foo()",
            "let foo = init()",
        ]) + ExplicitInitRule.description.nonTriggeringExamples

        let triggeringExamples = #examples([
            "let foo: Foo = ↓.init()",
            "let foo: [Foo] = [↓.init(), ↓.init()]",
            "foo(↓.init())",
        ])

        let description = ExplicitInitRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["include_bare_init": true])
    }
}
