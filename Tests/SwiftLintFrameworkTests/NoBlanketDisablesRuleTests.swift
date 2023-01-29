@testable import SwiftLintFramework
import XCTest

class NoBlanketDisablesRuleTests: XCTestCase {
    func testExamples() {
        verifyRule(NoBlanketDisablesRule.description, skipCommentTests: true, skipDisableCommandTests: true)
    }
}
