@testable import SwiftLintBuiltInRules
import SwiftLintFramework

class DiscouragedDirectInitRuleTests: SwiftLintTestCase {
    private let baseDescription = DiscouragedDirectInitRule.description

    func testDiscouragedDirectInitWithConfiguredSeverity() {
        verifyRule(baseDescription, ruleConfiguration: ["severity": "error"])
    }

    func testDiscouragedDirectInitWithNewIncludedTypes() {
        let triggeringExamples = [
            Example("let foo = ↓Foo()"),
            Example("let bar = ↓Bar()")
        ]

        let nonTriggeringExamples = [
            Example("let foo = Foo(arg: toto)"),
            Example("let bar = Bar(arg: \"toto\")")
        ]

        let description = baseDescription
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["types": ["Foo", "Bar"]])
    }

    func testDiscouragedDirectInitWithReplacedTypes() {
        let triggeringExamples = [
            Example("let bundle = ↓Bundle()")
        ]

        let nonTriggeringExamples = [
            Example("let device = UIDevice()")
        ]

        let description = baseDescription
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["types": ["Bundle"]])
    }
}
