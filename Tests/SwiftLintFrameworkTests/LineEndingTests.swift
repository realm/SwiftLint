@testable import SwiftLintFramework
import XCTest

class LineEndingTests: XCTestCase {
    func testCarriageReturnDoesNotCauseError() {
        XCTAssert(
            violations(
                Example("//swiftlint:disable all\r\nprint(123)\r\n")
            ).isEmpty
        )
    }
}
