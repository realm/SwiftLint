import SwiftLintFramework
import XCTest

class ScopeDepthRuleTests: XCTestCase {
    func testScopeDepthWithDefaultConfiguration() {
        verifyRule(ScopeDepthRule.description)
    }
}
