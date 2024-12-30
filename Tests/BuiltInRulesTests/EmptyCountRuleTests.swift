@testable import SwiftLintBuiltInRules
import TestHelpers

final class EmptyCountRuleTests: SwiftLintTestCase {
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
            Example("count == 0\n"),
        ]
        let triggeringExamples = [
            Example("[Int]().↓count == 0\n"),
            Example("[Int]().↓count > 0\n"),
            Example("[Int]().↓count != 0\n"),
            Example("[Int]().↓count == 0x0\n"),
            Example("[Int]().↓count == 0x00_00\n"),
            Example("[Int]().↓count == 0b00\n"),
            Example("[Int]().↓count == 0o00\n"),
        ]

        let corrections = [
            Example("[].↓count == 0"):
                Example("[].isEmpty"),
            Example("0 == [].↓count"):
                Example("[].isEmpty"),
            Example("[Int]().↓count == 0"):
                Example("[Int]().isEmpty"),
            Example("0 == [Int]().↓count"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count==0"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count > 0"):
                Example("![Int]().isEmpty"),
            Example("[Int]().↓count != 0"):
                Example("![Int]().isEmpty"),
            Example("[Int]().↓count == 0x0"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count == 0x00_00"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count == 0b00"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count == 0o00"):
                Example("[Int]().isEmpty"),
            Example("count == 0"):
                Example("count == 0"),
            Example("count == 0 && [Int]().↓count == 0o00"):
                Example("count == 0 && [Int]().isEmpty"),
            Example("[Int]().count != 3 && [Int]().↓count != 0 || count == 0 && [Int]().count > 2"):
                Example("[Int]().count != 3 && ![Int]().isEmpty || count == 0 && [Int]().count > 2"),
        ]

        let description = EmptyCountRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["only_after_dot": true])
    }
}
