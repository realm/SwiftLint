import SwiftLintCore
import XCTest

class LineEndingTests: SwiftLintTestCase {
    func testCarriageReturnDoesNotCauseError() {
        XCTAssert(
            violations(
                Example("// swiftlint:disable all\r\nprint(123)\r\n")
            ).isEmpty
        )
    }
}
