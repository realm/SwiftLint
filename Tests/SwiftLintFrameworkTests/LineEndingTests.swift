@testable import SwiftLintFramework
import XCTest

class LineEndingTests: XCTestCase {
    func testCarriageReturnDoesNotCauseError() async {
        let results = await violations(
            Example("// swiftlint:disable all\r\nprint(123)\r\n")
        )
        XCTAssert(results.isEmpty)
    }
}
