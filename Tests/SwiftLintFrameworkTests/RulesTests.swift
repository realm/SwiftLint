@testable import SwiftLintFramework
import XCTest

class RulesTests: XCTestCase {
    func testLeadingWhitespace() async throws {
        try await verifyRule(LeadingWhitespaceRule.description, skipDisableCommandTests: true,
                             testMultiByteOffsets: false, testShebang: false)
    }

    func testMark() async throws {
        try await verifyRule(MarkRule.description, skipCommentTests: true)
    }

    func testRequiredEnumCase() async throws {
        let configuration = ["NetworkResponsable": ["notConnected": "error"]]
        try await verifyRule(RequiredEnumCaseRule.description, ruleConfiguration: configuration)
    }

    func testTrailingNewline() async throws {
        try await verifyRule(TrailingNewlineRule.description, commentDoesntViolate: false,
                             stringDoesntViolate: false)
    }

    func testOrphanedDocComment() async throws {
        try await verifyRule(OrphanedDocCommentRule.description, commentDoesntViolate: false, skipCommentTests: true)
    }
}
