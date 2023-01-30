@testable import SwiftLintFramework
import XCTest

class StatementPositionRuleTests: XCTestCase {
    func testStatementPositionUncuddled() async throws {
        let configuration = ["statement_mode": "uncuddled_else"]
        try await verifyRule(StatementPositionRule.uncuddledDescription, ruleConfiguration: configuration)
    }
}
