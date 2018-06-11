import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class BalancedBlankLinesRuleTests: XCTestCase {

    func testBalancedBlankLines() {
        verifyRule(BalancedBlankLinesRule.description)
    }

}
