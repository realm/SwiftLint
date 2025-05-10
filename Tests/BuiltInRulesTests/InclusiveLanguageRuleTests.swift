@testable import SwiftLintBuiltInRules
import TestHelpers

final class InclusiveLanguageRuleTests: SwiftLintTestCase {
    func testNonTriggeringExamplesWithNonDefaultConfig() {
        InclusiveLanguageRuleExamples.nonTriggeringExamplesWithConfig.forEach { example in
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [example])
                .with(triggeringExamples: [])
            verifyRule(description, ruleConfiguration: example.configuration)
        }
    }

    func testTriggeringExamplesWithNonDefaultConfig() {
        InclusiveLanguageRuleExamples.triggeringExamplesWithConfig.forEach { example in
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [])
                .with(triggeringExamples: [example])
            verifyRule(description, ruleConfiguration: example.configuration)
        }
    }
}
