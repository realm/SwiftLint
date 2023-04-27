@testable import SwiftLintBuiltInRules

class ImplicitReturnRuleTests: SwiftLintTestCase {
    func testOnlyClosureKindIncluded() {
        let nonTriggeringExamples = ImplicitReturnRuleExamples.GenericExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.ClosureExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.FunctionExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.FunctionExamples.triggeringExamples +
            ImplicitReturnRuleExamples.GetterExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.GetterExamples.triggeringExamples
        let triggeringExamples = ImplicitReturnRuleExamples.ClosureExamples.triggeringExamples
        let corrections = ImplicitReturnRuleExamples.ClosureExamples.corrections

        let description = ImplicitReturnRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        self.verifyRule(description, returnKind: .closure)
    }

    func testOnlyFunctionKindIncluded() {
        let nonTriggeringExamples = ImplicitReturnRuleExamples.GenericExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.ClosureExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.ClosureExamples.triggeringExamples +
            ImplicitReturnRuleExamples.FunctionExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.GetterExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.GetterExamples.triggeringExamples
        let triggeringExamples = ImplicitReturnRuleExamples.FunctionExamples.triggeringExamples
        let corrections = ImplicitReturnRuleExamples.FunctionExamples.corrections

        let description = ImplicitReturnRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        self.verifyRule(description, returnKind: .function)
    }

    func testOnlyGetterKindIncluded() {
        let nonTriggeringExamples = ImplicitReturnRuleExamples.GenericExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.ClosureExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.ClosureExamples.triggeringExamples +
            ImplicitReturnRuleExamples.FunctionExamples.nonTriggeringExamples +
            ImplicitReturnRuleExamples.FunctionExamples.triggeringExamples +
            ImplicitReturnRuleExamples.GetterExamples.nonTriggeringExamples
        let triggeringExamples = ImplicitReturnRuleExamples.GetterExamples.triggeringExamples
        let corrections = ImplicitReturnRuleExamples.GetterExamples.corrections

        let description = ImplicitReturnRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        self.verifyRule(description, returnKind: .getter)
    }

    private func verifyRule(_ ruleDescription: RuleDescription, returnKind: ImplicitReturnConfiguration.ReturnKind) {
        self.verifyRule(ruleDescription, ruleConfiguration: ["included": [returnKind.rawValue]])
    }
}
