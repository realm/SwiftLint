@testable import SwiftLintFramework
import XCTest

class RulesTests: XCTestCase {
    func testLeadingWhitespace() {
        verifyRule(LeadingWhitespaceRule.description, skipDisableCommandTests: true,
                   testMultiByteOffsets: false, testShebang: false)
    }

    func testMark() {
        verifyRule(MarkRule.description, skipCommentTests: true)
    }

    func testRequiredEnumCase() {
        let configuration = ["NetworkResponsable": ["notConnected": "error"]]
        verifyRule(RequiredEnumCaseRule.description, ruleConfiguration: configuration)
    }

    func testTrailingNewline() {
        verifyRule(TrailingNewlineRule.description, commentDoesntViolate: false,
                   stringDoesntViolate: false)
    }

    func testOrphanedDocComment() {
        verifyRule(OrphanedDocCommentRule.description, commentDoesntViolate: false, skipCommentTests: true)
    }

    func testUseCaseExposedFunctions() {
        verifyRule(UseCaseExposedFunctionsRule.description)
    }
}
