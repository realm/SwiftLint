import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ImplicitReturnRuleTests {
    @Test
    func onlyClosureKindIncluded() {
        var nonTriggeringExamples = ImplicitReturnRuleExamples.nonTriggeringExamples +
                                    ImplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ImplicitReturnRuleExamples.ClosureExamples.triggeringExamples.contains
        )

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ImplicitReturnRuleExamples.ClosureExamples.triggeringExamples,
            corrections: ImplicitReturnRuleExamples.ClosureExamples.corrections,
            kind: .closure
        )
    }

    @Test
    func onlyFunctionKindIncluded() {
        var nonTriggeringExamples = ImplicitReturnRuleExamples.nonTriggeringExamples +
                                    ImplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ImplicitReturnRuleExamples.FunctionExamples.triggeringExamples.contains
        )

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ImplicitReturnRuleExamples.FunctionExamples.triggeringExamples,
            corrections: ImplicitReturnRuleExamples.FunctionExamples.corrections,
            kind: .function
        )
    }

    @Test
    func onlyGetterKindIncluded() {
        var nonTriggeringExamples = ImplicitReturnRuleExamples.nonTriggeringExamples +
                                    ImplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ImplicitReturnRuleExamples.GetterExamples.triggeringExamples.contains
        )

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ImplicitReturnRuleExamples.GetterExamples.triggeringExamples,
            corrections: ImplicitReturnRuleExamples.GetterExamples.corrections,
            kind: .getter
        )
    }

    @Test
    func onlyInitializerKindIncluded() {
        var nonTriggeringExamples = ImplicitReturnRuleExamples.nonTriggeringExamples +
                                    ImplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ImplicitReturnRuleExamples.InitializerExamples.triggeringExamples.contains
        )

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ImplicitReturnRuleExamples.InitializerExamples.triggeringExamples,
            corrections: ImplicitReturnRuleExamples.InitializerExamples.corrections,
            kind: .initializer
        )
    }

    @Test
    func onlySubscriptKindIncluded() {
        var nonTriggeringExamples = ImplicitReturnRuleExamples.nonTriggeringExamples +
                                    ImplicitReturnRuleExamples.triggeringExamples
        nonTriggeringExamples.removeAll(
            where: ImplicitReturnRuleExamples.SubscriptExamples.triggeringExamples.contains
        )

        verifySubset(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: ImplicitReturnRuleExamples.SubscriptExamples.triggeringExamples,
            corrections: ImplicitReturnRuleExamples.SubscriptExamples.corrections,
            kind: .subscript
        )
    }

    private func verifySubset(
        nonTriggeringExamples: [Example],
        triggeringExamples: [Example],
        corrections: [Example: Example],
        kind: ImplicitReturnConfiguration.ReturnKind
    ) {
        let description = ImplicitReturnRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples.removingViolationMarker())
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["included": [kind.rawValue]])
    }
}
