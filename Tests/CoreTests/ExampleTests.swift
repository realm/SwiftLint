import SwiftLintFramework
import Testing

@Suite
struct ExampleTests {
    @Test
    func equatableDoesNotLookAtFile() {
        let first = Example(code: "foo", file: "a", line: 1)
        let second = Example(code: "foo", file: "b", line: 1)
        #expect(first == second)
    }

    @Test
    func equatableDoesNotLookAtLine() {
        let first = Example(code: "foo", file: "a", line: 1)
        let second = Example(code: "foo", file: "a", line: 2)
        #expect(first == second)
    }

    @Test
    func equatableLooksAtCode() {
        let first = Example(code: "a", file: "a", line: 1)
        let second = Example(code: "a", file: "x", line: 2)
        let third = Example(code: "c", file: "y", line: 2)
        #expect(first == second)
        #expect(first != third)
    }

    @Test
    func multiByteOffsets() {
        #expect(Example(code: "").testMultiByteOffsets)
        #expect(Example(code: "", testMultiByteOffsets: true).testMultiByteOffsets)
        #expect(!Example(code: "", testMultiByteOffsets: false).testMultiByteOffsets)
    }

    @Test
    func onLinux() {
        #expect(Example(code: "").testOnLinux)
        #expect(Example(code: "", testOnLinux: true).testOnLinux)
        #expect(!Example(code: "", testOnLinux: false).testOnLinux)
    }

    @Test
    func removingViolationMarkers() {
        let example = Example(code: "↓T↓E↓S↓T")
        #expect(example.removingViolationMarkers() == Example(code: "TEST"))
    }

    @Test
    func comparable() {
        #expect(Example(code: "a") < Example(code: "b"))
    }

    @Test
    func withCode() {
        let original = Example(code: "original code")
        #expect(original.code == "original code")

        let new = original.with(code: "new code")
        #expect(new.code == "new code")

        // When modifying the code, it's important that the file and line
        // numbers remain intact
        #expect(new.file.description == original.file.description)
        #expect(new.line == original.line)
    }
}
