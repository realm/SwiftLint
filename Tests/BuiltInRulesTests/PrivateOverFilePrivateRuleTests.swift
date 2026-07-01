import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct PrivateOverFilePrivateRuleTests {
    @Test
    func privateOverFilePrivateValidatingExtensions() {
        let baseDescription = PrivateOverFilePrivateRule.description
        let triggeringExamples = baseDescription.triggeringExamples + #examples([
            "↓fileprivate extension String {}",
            "↓fileprivate \n extension String {}",
            "↓fileprivate extension \n String {}",
        ])
        let corrections = #corrections([
            "↓fileprivate extension String {}": "private extension String {}",
            "↓fileprivate \n extension String {}": "private \n extension String {}",
            "↓fileprivate extension \n String {}": "private extension \n String {}",
        ])

        let description = baseDescription.with(nonTriggeringExamples: [])
            .with(triggeringExamples: triggeringExamples).with(corrections: corrections)
        verifyRule(description, ruleConfiguration: ["validate_extensions": true])
    }

    @Test
    func privateOverFilePrivateNotValidatingExtensions() {
        let baseDescription = PrivateOverFilePrivateRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + #examples([
            "fileprivate extension String {}"
        ])

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["validate_extensions": false])
    }
}
