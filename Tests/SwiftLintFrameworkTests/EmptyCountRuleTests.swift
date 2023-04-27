@testable import SwiftLintBuiltInRules

class EmptyCountRuleTests: SwiftLintTestCase {
    func testEmptyCountWithOnlyAfterDot() {
        // Test with `only_after_dot` set to true
        let nonTriggeringExamples = [
            Example("var count = 0\n"),
            Example("[Int]().isEmpty\n"),
            Example("[Int]().count > 1\n"),
            Example("[Int]().count == 1\n"),
            Example("[Int]().count == 0xff\n"),
            Example("[Int]().count == 0b01\n"),
            Example("[Int]().count == 0o07\n"),
            Example("discount == 0\n"),
            Example("order.discount == 0\n"),
            Example("count == 0\n")
        ]
        let triggeringExamples = [
            Example("[Int]().↓count == 0\n"),
            Example("[Int]().↓count > 0\n"),
            Example("[Int]().↓count != 0\n"),
            Example("[Int]().↓count == 0x0\n"),
            Example("[Int]().↓count == 0x00_00\n"),
            Example("[Int]().↓count == 0b00\n"),
            Example("[Int]().↓count == 0o00\n")
        ]

        let description = EmptyCountRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["only_after_dot": true])
    }
}
