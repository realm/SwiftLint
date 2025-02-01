import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct InclusiveLanguageRuleTests {
    @Test
    func nonTriggeringExamplesWithNonDefaultConfig() {
        InclusiveLanguageRuleExamples.nonTriggeringExamplesWithConfig.forEach { example in
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [example])
                .with(triggeringExamples: [])
            verifyRule(description, ruleConfiguration: example.configuration)
        }
    }

    @Test
    func triggeringExamplesWithNonDefaultConfig() {
        InclusiveLanguageRuleExamples.triggeringExamplesWithConfig.forEach { example in
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [])
                .with(triggeringExamples: [example])
            verifyRule(description, ruleConfiguration: example.configuration)
        }
    }
}
