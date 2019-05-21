import Foundation
@testable import SwiftLintFramework
import XCTest

class IndentationWidthRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        // Don't do crazy testing as this triggers invalid warnings
        verifyRule(
            IndentationWidthRule.description,
            skipCommentTests: true,
            skipDisableCommandTests: true,
            testMultiByteOffsets: false,
            testShebang: false
        )
    }
}
