@testable import SwiftLintFramework
import XCTest

class LineEndingTests: SwiftLintTestCase {
    func testCarriageReturnDoesNotCauseError() {
        XCTAssert(
            violations(
                Example(
                    "// swiftlint:disable:next blanket_disable_command\r\n" +
                    "// swiftlint:disable all\r\nprint(123)\r\n"
                )
            ).isEmpty
        )
    }
}
