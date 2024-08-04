@testable import SwiftLintBuiltInRules

final class RulesTests: SwiftLintTestCase {
    func testLeadingWhitespace() async {
        await verifyRule(
            LeadingWhitespaceRule.description,
            skipDisableCommandTests: true,
            testMultiByteOffsets: false,
            testShebang: false
        )
    }

    func testMark() async {
        await verifyRule(MarkRule.description, skipCommentTests: true)
    }

    func testRequiredEnumCase() async {
        let configuration = ["NetworkResponsable": ["notConnected": "error"]]
        await verifyRule(RequiredEnumCaseRule.description, ruleConfiguration: configuration)
    }

    func testTrailingNewline() async {
        await verifyRule(TrailingNewlineRule.description, commentDoesntViolate: false, stringDoesntViolate: false)
    }

    func testOrphanedDocComment() async {
        await verifyRule(OrphanedDocCommentRule.description, commentDoesntViolate: false, skipCommentTests: true)
    }
}
