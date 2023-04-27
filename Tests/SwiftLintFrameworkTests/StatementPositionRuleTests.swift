@testable import SwiftLintBuiltInRules

class StatementPositionRuleTests: SwiftLintTestCase {
    func testStatementPositionUncuddled() {
        let configuration = ["statement_mode": "uncuddled_else"]
        verifyRule(StatementPositionRule.uncuddledDescription, ruleConfiguration: configuration)
    }
}
