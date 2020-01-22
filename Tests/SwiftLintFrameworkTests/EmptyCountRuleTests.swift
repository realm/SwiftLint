@testable import SwiftLintFramework
import XCTest

class EmptyCountRuleTests: XCTestCase {
    func testEmptyCountWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(EmptyCountRule.description)
    }

    func testEmptyCountWithOnlyAfterDot() {
        // Test with `only_after_dot` set to true
        let nonTriggeringExamples = [
            "var count = 0\n",
            "[Int]().isEmpty\n",
            "[Int]().count > 1\n",
            "[Int]().count == 1\n",
            "[Int]().count == 0xff\n",
            "[Int]().count == 0b01\n",
            "[Int]().count == 0o07\n",
            "discount == 0\n",
            "order.discount == 0\n",
            "count == 0\n"
        ]
        let triggeringExamples = [
            "[Int]().↓count == 0\n",
            "[Int]().↓count > 0\n",
            "[Int]().↓count != 0\n",
            "[Int]().↓count == 0x0\n",
            "[Int]().↓count == 0x00_00\n",
            "[Int]().↓count == 0b00\n",
            "[Int]().↓count == 0o00\n"
        ]

        let description = EmptyCountRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["only_after_dot": true])
    }
}
