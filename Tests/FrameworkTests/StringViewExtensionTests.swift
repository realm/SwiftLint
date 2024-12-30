import SourceKittenFramework
import XCTest

final class StringViewExtensionTests: SwiftLintTestCase {
    func testByteOffsetInvalidCases() {
        let view = StringView("")

        XCTAssertNil(view.byteOffset(forLine: 0, bytePosition: 1))
        XCTAssertNil(view.byteOffset(forLine: 1, bytePosition: 0))
        XCTAssertNil(view.byteOffset(forLine: -10, bytePosition: 1))
        XCTAssertNil(view.byteOffset(forLine: 0, bytePosition: -11))
        XCTAssertNil(view.byteOffset(forLine: 2, bytePosition: 1))
    }

    func testByteOffsetFromLineAndBytePosition() {
        XCTAssertEqual(StringView("").byteOffset(forLine: 1, bytePosition: 1), 0)
        XCTAssertEqual(StringView("a").byteOffset(forLine: 1, bytePosition: 1), 0)
        XCTAssertEqual(StringView("aaa").byteOffset(forLine: 1, bytePosition: 3), 2)
        XCTAssertEqual(StringView("a🍰a").byteOffset(forLine: 1, bytePosition: 6), 5)
        XCTAssertEqual(StringView("a🍰a\na").byteOffset(forLine: 2, bytePosition: 1), 7)
    }
}
