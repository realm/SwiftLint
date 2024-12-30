@testable import SwiftLintBuiltInRules
import TestHelpers

final class ExplicitInitRuleTests: SwiftLintTestCase {
    func testIncludeBareInit() {
        let nonTriggeringExamples = [
            Example("let foo = Foo()"),
            Example("let foo = init()"),
        ] + ExplicitInitRule.description.nonTriggeringExamples

        let triggeringExamples = [
            Example("let foo: Foo = ↓.init()"),
            Example("let foo: [Foo] = [↓.init(), ↓.init()]"),
            Example("foo(↓.init())"),
        ]

        let description = ExplicitInitRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["include_bare_init": true])
    }
}
