@testable import SwiftLintBuiltInRules
import TestHelpers

final class ExplicitReturnRuleTests: SwiftLintTestCase {
    func testOnlyClosureKindIncluded() {
        var nonTriggeringExamples = ExplicitReturnRuleExamples.nonTriggeringExamples +
                                    ExplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ExplicitReturnRuleExamples.ClosureExamples.triggeringExamples.contains
        )
        nonTriggeringExamples.removeAll { $0.configuration != nil }

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ExplicitReturnRuleExamples.ClosureExamples.triggeringExamples,
            corrections: ExplicitReturnRuleExamples.ClosureExamples.corrections,
            kind: .closure
        )
    }

    func testOnlyFunctionKindIncluded() {
        var nonTriggeringExamples = ExplicitReturnRuleExamples.nonTriggeringExamples +
                                    ExplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ExplicitReturnRuleExamples.FunctionExamples.triggeringExamples.contains
        )
        nonTriggeringExamples.removeAll { $0.configuration != nil }

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ExplicitReturnRuleExamples.FunctionExamples.triggeringExamples,
            corrections: ExplicitReturnRuleExamples.FunctionExamples.corrections,
            kind: .function
        )
    }

    func testOnlyGetterKindIncluded() {
        var nonTriggeringExamples = ExplicitReturnRuleExamples.nonTriggeringExamples +
                                    ExplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ExplicitReturnRuleExamples.GetterExamples.triggeringExamples.contains
        )
        nonTriggeringExamples.removeAll { $0.configuration != nil }

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ExplicitReturnRuleExamples.GetterExamples.triggeringExamples,
            corrections: ExplicitReturnRuleExamples.GetterExamples.corrections,
            kind: .getter
        )
    }

    func testOnlyInitializerKindIncluded() {
        var nonTriggeringExamples = ExplicitReturnRuleExamples.nonTriggeringExamples +
                                    ExplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ExplicitReturnRuleExamples.InitializerExamples.triggeringExamples.contains
        )
        nonTriggeringExamples.removeAll { $0.configuration != nil }

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ExplicitReturnRuleExamples.InitializerExamples.triggeringExamples,
            corrections: ExplicitReturnRuleExamples.InitializerExamples.corrections,
            kind: .initializer
        )
    }

    func testOnlySubscriptKindIncluded() {
        var nonTriggeringExamples = ExplicitReturnRuleExamples.nonTriggeringExamples +
                                    ExplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ExplicitReturnRuleExamples.SubscriptExamples.triggeringExamples.contains
        )
        nonTriggeringExamples.removeAll { $0.configuration != nil }

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ExplicitReturnRuleExamples.SubscriptExamples.triggeringExamples,
            corrections: ExplicitReturnRuleExamples.SubscriptExamples.corrections,
            kind: .subscript
        )
    }

    private func verifySubset(
        nonTriggeringExamples: [Example],
        triggeringExamples: [Example],
        corrections: [Example: Example],
        kind: ExplicitReturnConfiguration.ReturnKind
    ) {
        let description = ExplicitReturnRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples.removingViolationMarker())
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["included": [kind.rawValue]])
    }
}
