import SwiftLintFramework
import XCTest

class StatementPositionRuleTests: XCTestCase {
    func testStatementPosition() async {
        await verifyRule(StatementPositionRule.description)
    }

    func testStatementPositionUncuddled() async {
        let configuration = ["statement_mode": "uncuddled_else"]
        await verifyRule(StatementPositionRule.uncuddledDescription, ruleConfiguration: configuration)
    }
}
