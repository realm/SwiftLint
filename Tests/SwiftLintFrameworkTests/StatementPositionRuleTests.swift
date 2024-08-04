@testable import SwiftLintBuiltInRules

final class StatementPositionRuleTests: SwiftLintTestCase {
    func testStatementPositionUncuddled() async {
        let configuration = ["statement_mode": "uncuddled_else"]
        await verifyRule(StatementPositionRule.uncuddledDescription, ruleConfiguration: configuration)
    }
}
