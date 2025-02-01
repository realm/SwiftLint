import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct SwitchCaseAlignmentRuleTests {
    @Test
    func switchCaseAlignmentWithoutIndentedCases() {
        let baseDescription = SwitchCaseAlignmentRule.description
        let examples = SwitchCaseAlignmentRule.Examples(indentedCases: false)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        verifyRule(description)
    }

    @Test
    func switchCaseAlignmentWithIndentedCases() {
        let baseDescription = SwitchCaseAlignmentRule.description
        let examples = SwitchCaseAlignmentRule.Examples(indentedCases: true)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        verifyRule(description, ruleConfiguration: ["indented_cases": true])
    }
}
