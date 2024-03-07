@testable import SwiftLintBuiltInRules

class SwitchCaseOnNewlineRuleTests: SwiftLintTestCase {
    func testSwitchCaseOnNewlineAllowingReturnlessCases() {
        verifyRule(
            SwitchCaseOnNewlineRule.description.with(
                nonTriggeringExamples: [
                    Example("""
                    let value = switch foo {
                        case 1: true
                    }
                    """)
                ],
                triggeringExamples: [
                    Example("""
                    var value = false
                    switch foo {
                        ↓case 1: value = true
                    }
                    """)
                ]
            ),
            ruleConfiguration: ["skip_switch_expressions": true]
        )
    }
}
