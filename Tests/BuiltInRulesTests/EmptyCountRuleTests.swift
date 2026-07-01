import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct EmptyCountRuleTests {
    @Test
    func emptyCountWithOnlyAfterDot() {
        // Test with `only_after_dot` set to true
        let nonTriggeringExamples = #examples([
            "var count = 0\n",
            "[Int]().isEmpty\n",
            "[Int]().count > 1\n",
            "[Int]().count == 1\n",
            "[Int]().count == 0xff\n",
            "[Int]().count == 0b01\n",
            "[Int]().count == 0o07\n",
            "discount == 0\n",
            "order.discount == 0\n",
            "count == 0\n",
            "let rule = #Rule(Tips.Event(id: \"someTips\")) { $0.donations.isEmpty }",
        ])
        let triggeringExamples = #examples([
            "[Int]().↓count == 0\n",
            "[Int]().↓count > 0\n",
            "[Int]().↓count != 0\n",
            "[Int]().↓count == 0x0\n",
            "[Int]().↓count == 0x00_00\n",
            "[Int]().↓count == 0b00\n",
            "[Int]().↓count == 0o00\n",
            "#ExampleMacro { $0.list.↓count == 0 }",
        ])

        let corrections = #examplesDictionary([
            "[].↓count == 0":
                "[].isEmpty",
            "0 == [].↓count":
                "[].isEmpty",
            "[Int]().↓count == 0":
                "[Int]().isEmpty",
            "0 == [Int]().↓count":
                "[Int]().isEmpty",
            "[Int]().↓count==0":
                "[Int]().isEmpty",
            "[Int]().↓count > 0":
                "![Int]().isEmpty",
            "[Int]().↓count != 0":
                "![Int]().isEmpty",
            "[Int]().↓count == 0x0":
                "[Int]().isEmpty",
            "[Int]().↓count == 0x00_00":
                "[Int]().isEmpty",
            "[Int]().↓count == 0b00":
                "[Int]().isEmpty",
            "[Int]().↓count == 0o00":
                "[Int]().isEmpty",
            "count == 0":
                "count == 0",
            "count == 0 && [Int]().↓count == 0o00":
                "count == 0 && [Int]().isEmpty",
            "[Int]().count != 3 && [Int]().↓count != 0 || count == 0 && [Int]().count > 2":
                "[Int]().count != 3 && ![Int]().isEmpty || count == 0 && [Int]().count > 2",
            "#ExampleMacro { $0.list.↓count == 0 }":
                "#ExampleMacro { $0.list.isEmpty }",
        ])

        let description = EmptyCountRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["only_after_dot": true])
    }
}
