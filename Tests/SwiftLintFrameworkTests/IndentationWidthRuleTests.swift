import Foundation
@testable import SwiftLintFramework
import XCTest

class IndentationWidthRuleTests: XCTestCase {
    func testTriggeringExamples() {
        let triggeringExamples = [
            "firstLine\n\t    secondLine", // It's not okay to indent using both tabs and spaces in one line
            "    firstLine", // It's not okay to have the first line indented
            "firstLine\n        secondLine", // It's not okay to indent using neither one tab or indentationWidth spaces
            "firstLine\n\t\tsecondLine", // It's not okay to indent using multiple tabs
            "firstLine\n\tsecondLine\n\n\t\t\tfourthLine",
            // It's okay to have empty lines between, but then, the following indentation must obey the rules
            "firstLine\n    secondLine\n        thirdLine\n fourthLine"
            // It's not okay to unindent indentationWidth * (1, 2, 3, ...) - 3
        ]

        // Don't do crazy testing as this triggers invalid warnings
        verifyRule(
            IndentationWidthRule.description.with(nonTriggeringExamples: [], triggeringExamples: triggeringExamples),
            skipCommentTests: true,
            skipDisableCommandTests: true,
            testMultiByteOffsets: false,
            testShebang: false
        )
    }

    func testNonTriggeringExamples() {
        let nonTriggeringExamples = [
            "firstLine\nsecondLine", // It's okay to keep the same indentation
            "firstLine\n    secondLine", // It's okay to indent using the specified indentationWidth
            "firstLine\n\tsecondLine", // It's okay to indent using a tab
            "firstLine\n\tsecondLine\n\t\tthirdLine\n\n\t\tfourthLine", // It's okay to have empty lines between
            "firstLine\n\tsecondLine\n\t\tthirdLine\n \n\t\tfourthLine", // It's okay to have empty lines between
            // "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n\t\tfourthLine", // It's okay to have comment lines between
            "firstLine\n    secondLine\n        thirdLine\nfourthLine"
            // It's okay to unindent indentationWidth * (1, 2, 3, ...)
        ]

        // Don't do crazy testing as this triggers invalid warnings
        verifyRule(
            IndentationWidthRule.description.with(nonTriggeringExamples: nonTriggeringExamples, triggeringExamples: []),
            skipCommentTests: true,
            skipDisableCommandTests: true,
            testMultiByteOffsets: false,
            testShebang: false
        )
    }
}
