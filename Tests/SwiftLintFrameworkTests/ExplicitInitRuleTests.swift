@testable import SwiftLintBuiltInRules

class ExplicitInitRuleTests: SwiftLintTestCase {
    func testIncludeBareInit() {
        let nonTriggeringExamples = [
            Example("let foo = Foo()"),
            Example("let foo = init()"),
            Example("let foo = Foo.init()")
        ] + ExplicitInitRule.description.nonTriggeringExamples
          + ExplicitInitRule.description.triggeringExamples.map { $0.removingViolationMarkers() }

        let triggeringExamples = [
            Example("let foo: Foo = ↓.init()"),
            Example("let foo: [Foo] = [↓.init(), ↓.init()]"),
            Example("foo(↓.init())")
        ]

        let description = ExplicitInitRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: [:])

        verifyRule(description, ruleConfiguration: ["include_explicit_init": false, "include_bare_init": true])
    }
}
