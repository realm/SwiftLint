import SwiftLintFramework
import XCTest

class StatementPositionRuleConfigurationTests: XCTestCase {
    func testStatementPositionUncuddled() {
        let configuration = ["statement_mode": "uncuddled_else"]
        verifyRule(StatementPositionRule.uncuddledDescription, ruleConfiguration: configuration)
    }
}
