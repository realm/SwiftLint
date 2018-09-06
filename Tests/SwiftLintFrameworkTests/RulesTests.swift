import SwiftLintFramework
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

    // Remove and make UnusedPrivateDeclarationRule conform to AutomaticTestableRule
    // when CircleCI updates its Xcode 10 image to the GM release.
    func testUnusedPrivateDeclaration() {
#if swift(>=4.1.50) && !SWIFT_PACKAGE
        print("\(#function) is failing with Xcode 10 on CirclCI")
#else
        verifyRule(UnusedPrivateDeclarationRule.description)
#endif
    }
}
