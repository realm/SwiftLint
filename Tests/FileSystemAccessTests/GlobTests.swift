import FilenameMatcher
import TestHelpers
import XCTest

@testable import SwiftLintFramework

final class GlobTests: SwiftLintTestCase {
    private let mockPath = TestResources.path().appending(path: "ProjectMock", directoryHint: .isDirectory)

    func testNonExistingDirectory() {
        XCTAssertTrue(Glob.resolveGlob("./bar/**".url()).isEmpty)
    }

    func testOnlyGlobForWildcard() {
        let files = Glob.resolveGlob("foo/bar.swift".url())
        XCTAssertEqual(files, ["foo/bar.swift".url()])
    }

    func testNoMatchReturnsEmpty() {
        let files = Glob.resolveGlob(mockPath.appending(path: "NoFile*.swift"))
        XCTAssertTrue(files.isEmpty)
    }

    func testMatchesFiles() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level*.swift"))
        XCTAssertEqual(files, [mockPath.appending(path: "Level0.swift")])
    }

    func testMatchesSingleCharacter() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level?.swift"))
        XCTAssertEqual(files, [mockPath.appending(path: "Level0.swift")])
    }

    #if !os(Windows)
    func testMatchesOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level[01].swift"))
        XCTAssertEqual(files, [mockPath.appending(path: "Level0.swift")])
    }

    func testNoMatchOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level[ab].swift"))
        XCTAssertTrue(files.isEmpty)
    }

    func testMatchesCharacterInRange() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level[0-9].swift"))
        XCTAssertEqual(files, [mockPath.appending(path: "Level0.swift")])
    }

    func testNoMatchCharactersInRange() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level[a-z].swift"))
        XCTAssertTrue(files.isEmpty)
    }
    #endif

    func testMatchesMultipleFiles() {
        let expectedFiles = [
            mockPath.appending(path: "Level0.swift"),
            mockPath.appending(path: "Directory.swift/"),
        ]

        let files = Glob.resolveGlob(mockPath.appending(path: "*.swift"))
        AssertEqualInAnyOder(files, expectedFiles)
    }

    func testMatchesNestedDirectory() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level1/*.swift"))
        XCTAssertEqual(files, [mockPath.appending(path: "Level1/Level1.swift")])
    }

    func testGlobstarSupport() {
        if #unavailable(macOS 26) {
            // Older versions have double slashes in the returned paths.
            return
        }

        let expectedFiles = [
            "Directory.swift/",
            "Directory.swift/DirectoryLevel1.swift",
            "Level0.swift",
            "Level1/Level1.swift",
            "Level1/Level2/Level2.swift",
            "Level1/Level2/Level3/Level3.swift",
            "NestedConfig/Test/Main.swift",
            "NestedConfig/Test/Sub/Sub.swift",
        ].map { mockPath.appending(path: $0) }

        let files = Glob.resolveGlob(mockPath.appending(path: "**/*.swift"))
        AssertEqualInAnyOder(files, expectedFiles)
    }

    func testCreateFilenameMatchers() {
        func assertGlobMatch(pattern: String, filename: String, file: StaticString = #filePath, line: UInt = #line) {
            #if os(Windows)
            var pattern = pattern
            var filename = filename
            pattern = "C:" + pattern
            filename = "C:" + filename
            #endif
            let matchers = Glob.createFilenameMatchers(pattern: pattern)
            XCTAssert(matchers.anyMatch(filename: filename), file: file, line: line)
        }

        assertGlobMatch(pattern: "/a/b/c/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(pattern: "/a**/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(pattern: "/a**/*.swift", filename: "/a/b.swift")
        assertGlobMatch(pattern: "/**/*.swift", filename: "/a/b.swift")
        assertGlobMatch(pattern: "/a/**/b.swift", filename: "/a/b.swift")
        assertGlobMatch(pattern: "/a/**/b.swift", filename: "/a/c/b.swift")
        assertGlobMatch(pattern: "/**/*.swift", filename: "/a.swift")
        assertGlobMatch(pattern: "/a/**/*.swift", filename: "/a/b/c.swift")
        assertGlobMatch(pattern: "/a/**/*.swift", filename: "/a/b.swift")

        assertGlobMatch(pattern: "/a/b/c", filename: "/a/b/c/d.swift")
        assertGlobMatch(pattern: "/a/b/c/", filename: "/a/b/c/d.swift")
        assertGlobMatch(pattern: "/a/b/c/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(pattern: "/d.swift/*.swift", filename: "/d.swift/e.swift")
        assertGlobMatch(pattern: "/a/**", filename: "/a/b/c/d.swift")
        assertGlobMatch(pattern: "/**/*Test*", filename: "/a/b/c/MyTest2.swift")
        assertGlobMatch(pattern: "/**/*Test*", filename: "/a/b/MyTests/c.swift")
    }

    // swiftlint:disable:next identifier_name
    private func AssertEqualInAnyOder(_ lhs: [URL], _ rhs: [URL], file: StaticString = #filePath, line: UInt = #line) {
        func compare(lhs: URL, rhs: URL) -> Bool {
            lhs.path < rhs.path
        }
        XCTAssertEqual(lhs.sorted(by: compare), rhs.sorted(by: compare), file: file, line: line)
    }
}
