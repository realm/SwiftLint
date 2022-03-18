@testable import SwiftLintFramework
import XCTest

class ExplicitReturnRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(ExplicitReturnRule.description)
    }

    func testOnlyClosureKindIncluded() {
        let triggeringExamples = ExplicitReturnRuleExamples.ClosureExamples.triggeringExamples
        let corrections = ExplicitReturnRuleExamples.ClosureExamples.corrections

        let description = ExplicitReturnRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        self.verifyRule(description, returnKind: .closure)
    }

    func testOnlyFunctionKindIncluded() {
        let triggeringExamples = ExplicitReturnRuleExamples.FunctionExamples.triggeringExamples
        let corrections = ExplicitReturnRuleExamples.FunctionExamples.corrections

        let description = ExplicitReturnRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        self.verifyRule(description, returnKind: .function)
    }

    func testOnlyGetterKindIncluded() {
        let triggeringExamples = ExplicitReturnRuleExamples.GetterExamples.triggeringExamples
        let corrections = ExplicitReturnRuleExamples.GetterExamples.corrections

        let description = ExplicitReturnRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        self.verifyRule(description, returnKind: .getter)
    }

    private func verifyRule(_ ruleDescription: RuleDescription, returnKind: ExplicitReturnConfiguration.ReturnKind) {
        self.verifyRule(ruleDescription, ruleConfiguration: ["included": [returnKind.rawValue]])
    }
}
