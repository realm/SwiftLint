@testable import SwiftLintFramework
import XCTest

class SwitchCaseSortTests: XCTestCase {
    func testSwitchCaseSortExpression() {
        verifyRule(SwitchCaseSort.description)
    }
}
