import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct DiscouragedDirectInitRuleTests {
    private let baseDescription = DiscouragedDirectInitRule.description

    @Test
    func discouragedDirectInitWithConfiguredSeverity() {
        verifyRule(baseDescription, ruleConfiguration: ["severity": "error"])
    }

    @Test
    func discouragedDirectInitWithNewIncludedTypes() {
        let triggeringExamples = #examples([
            "let foo = ↓Foo()",
            "let bar = ↓Bar()",
        ])

        let nonTriggeringExamples = #examples([
            "let foo = Foo(arg: toto)",
            "let bar = Bar(arg: \"toto\")",
        ])

        let description = baseDescription
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["types": ["Foo", "Bar"]])
    }

    @Test
    func discouragedDirectInitWithReplacedTypes() {
        let triggeringExamples = #examples([
            "let bundle = ↓Bundle()"
        ])

        let nonTriggeringExamples = #examples([
            "let device = UIDevice()"
        ])

        let description = baseDescription
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["types": ["Bundle"]])
    }
}
