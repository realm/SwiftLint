@testable import SwiftLintFramework
import XCTest

class LineEndingTests: XCTestCase {
    func testCarriageReturnDoesNotCauseError() async throws {
        let violations = try await violations(Example("// swiftlint:disable all\r\nprint(123)\r\n"))
        XCTAssertEqual(violations, [])
    }
}
