import SwiftLintFramework
import XCTest

class ExampleTests: SwiftLintTestCase {
    func testEquatableDoesNotLookAtFile() {
        let first = Example("foo", file: "a", line: 1)
        let second = Example("foo", file: "b", line: 1)
        XCTAssertEqual(first, second)
    }

    func testEquatableDoesNotLookAtLine() {
        let first = Example("foo", file: "a", line: 1)
        let second = Example("foo", file: "a", line: 2)
        XCTAssertEqual(first, second)
    }

    func testEquatableLooksAtCode() {
        let first = Example("a", file: "a", line: 1)
        let second = Example("a", file: "x", line: 2)
        let third = Example("c", file: "y", line: 2)
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, third)
    }

    func testTestMultiByteOffsets() {
        XCTAssertTrue(Example("").testMultiByteOffsets)
        XCTAssertTrue(Example("", testMultiByteOffsets: true).testMultiByteOffsets)
        XCTAssertFalse(Example("", testMultiByteOffsets: false).testMultiByteOffsets)
    }

    func testTestOnLinux() {
        XCTAssertTrue(Example("").testOnLinux)
        XCTAssertTrue(Example("", testOnLinux: true).testOnLinux)
        XCTAssertFalse(Example("", testOnLinux: false).testOnLinux)
    }

    func testRemovingViolationMarkers() {
        let example = Example("↓T↓E↓S↓T")
        XCTAssertEqual(example.removingViolationMarkers(), Example("TEST"))
    }

    func testComparable() {
        XCTAssertLessThan(Example("a"), Example("b"))
    }

    func testWithCode() {
        let original = Example("original code")
        XCTAssertNotNil(original.file)
        XCTAssertNotNil(original.line)

        let new = original.with(code: "new code")
        XCTAssertEqual(new.code, "new code")
        XCTAssertNotNil(new.file)
        XCTAssertNotNil(new.line)

        // When modifying the code, it's important that the file and line
        // numbers remain intact
        XCTAssertEqual(new.file.description, original.file.description)
        XCTAssertEqual(new.line, original.line)
    }
}
