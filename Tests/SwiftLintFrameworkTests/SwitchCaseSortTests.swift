@testable import SwiftLintFramework
import XCTest

class SwitchCaseSortTests: XCTestCase {
    func testSwitchCaseSortExpression() {
        let baseDescription = SwitchCaseSort.description
        verifyRule(baseDescription)
    }
}
