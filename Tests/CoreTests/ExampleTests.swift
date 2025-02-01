import SwiftLintFramework
import Testing

@Suite
struct ExampleTests {
    @Test
    func equatableDoesNotLookAtFile() {
        let first = Example("foo", file: "a", line: 1)
        let second = Example("foo", file: "b", line: 1)
        #expect(first == second)
    }

    @Test
    func equatableDoesNotLookAtLine() {
        let first = Example("foo", file: "a", line: 1)
        let second = Example("foo", file: "a", line: 2)
        #expect(first == second)
    }

    @Test
    func equatableLooksAtCode() {
        let first = Example("a", file: "a", line: 1)
        let second = Example("a", file: "x", line: 2)
        let third = Example("c", file: "y", line: 2)
        #expect(first == second)
        #expect(first != third)
    }

    @Test
    func testMultiByteOffsets() {
        #expect(Example("").testMultiByteOffsets)
        #expect(Example("", testMultiByteOffsets: true).testMultiByteOffsets)
        #expect(!Example("", testMultiByteOffsets: false).testMultiByteOffsets)
    }

    @Test
    func testOnLinux() {
        #expect(Example("").testOnLinux)
        #expect(Example("", testOnLinux: true).testOnLinux)
        #expect(!Example("", testOnLinux: false).testOnLinux)
    }

    @Test
    func removingViolationMarkers() {
        let example = Example("↓T↓E↓S↓T")
        #expect(example.removingViolationMarkers() == Example("TEST"))
    }

    @Test
    func comparable() {
        #expect(Example("a") < Example("b"))
    }

    @Test
    func withCode() {
        let original = Example("original code")
        #expect(original.code == "original code")

        let new = original.with(code: "new code")
        #expect(new.code == "new code")

        // When modifying the code, it's important that the file and line
        // numbers remain intact
        #expect(new.file.description == original.file.description)
        #expect(new.line == original.line)
    }
}
