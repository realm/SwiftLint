@testable import SwiftLintBuiltInRules

final class SwitchCaseAlignmentRuleTests: SwiftLintTestCase {
    func testSwitchCaseAlignmentWithoutIndentedCases() async {
        let baseDescription = SwitchCaseAlignmentRule.description
        let examples = SwitchCaseAlignmentRule.Examples(indentedCases: false)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        await verifyRule(description)
    }

    func testSwitchCaseAlignmentWithIndentedCases() async {
        let baseDescription = SwitchCaseAlignmentRule.description
        let examples = SwitchCaseAlignmentRule.Examples(indentedCases: true)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        await verifyRule(description, ruleConfiguration: ["indented_cases": true])
    }
}
