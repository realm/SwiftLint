@testable import SwiftLintFramework
import XCTest

class InvalidSwiftLintCommandRuleTests: XCTestCase {
    func testExamples() {
        verifyRule(InvalidSwiftLintCommandRule.description, skipCommentTests: true, skipDisableCommandTests: true)
    }
}
