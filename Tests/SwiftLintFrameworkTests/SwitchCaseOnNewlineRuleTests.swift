@testable import SwiftLintBuiltInRules

class SwitchCaseOnNewlineRuleTests: SwiftLintTestCase {
    func testSwitchCaseOnNewlineAllowingReturnlessCases() {
        verifyRule(
            SwitchCaseOnNewlineRule.description.with(
                nonTriggeringExamples: [
                    wrapInSwitch("case 1: true"),
                    wrapInSwitch("case let value: true"),
                    wrapInSwitch("default: true"),
                    wrapInSwitch("case \"a string\": false"),
                    wrapInSwitch("case .myCase: false // error from network"),
                    wrapInSwitch("case let .myCase(value) where value > 10: false"),
                    wrapInSwitch("case #selector(aFunction(_:)): false"),
                    wrapInSwitch("case let .myCase(value)\n where value > 10: false"),
                    wrapInSwitch("case .first,\n .second: false")
                ],
                triggeringExamples: [
                    wrapInSwitch("↓case 1: return true"),
                    wrapInSwitch("↓case let value: return true"),
                    wrapInSwitch("↓default: return true"),
                    wrapInSwitch("↓case \"a string\": return false"),
                    wrapInSwitch("↓case .myCase: return false // error from network"),
                    wrapInSwitch("↓case let .myCase(value) where value > 10: return false"),
                    wrapInSwitch("↓case #selector(aFunction(_:)): return false"),
                    wrapInSwitch("↓case let .myCase(value)\n where value > 10: return false"),
                    wrapInSwitch("↓case .first,\n .second: return false")
                ]
            ),
            ruleConfiguration: ["allow_returnless_cases": true]
        )
    }
}

private func wrapInSwitch(_ str: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
    switch foo {
        \(str)
    }
    """, file: file, line: line)
}
