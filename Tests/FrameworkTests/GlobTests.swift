@testable import SwiftLintFramework
import TestHelpers
import XCTest

final class GlobTests: SwiftLintTestCase {
    private var mockPath: String {
        TestResources.path().stringByAppendingPathComponent("ProjectMock")
    }

    func testNonExistingDirectory() {
        XCTAssertTrue(Glob.resolveGlob("./bar/**").isEmpty)
    }

    func testOnlyGlobForWildcard() {
        let files = Glob.resolveGlob("foo/bar.swift")
        XCTAssertEqual(files, ["foo/bar.swift"])
    }

    func testNoMatchReturnsEmpty() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("NoFile*.swift"))
        XCTAssertTrue(files.isEmpty)
    }

    func testMatchesFiles() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level*.swift"))
        XCTAssertEqual(files, [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    func testMatchesSingleCharacter() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level?.swift"))
        XCTAssertEqual(files, [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    func testMatchesOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[01].swift"))
        XCTAssertEqual(files, [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    func testNoMatchOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[ab].swift"))
         XCTAssertTrue(files.isEmpty)
    }

    func testMatchesCharacterInRange() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[0-9].swift"))
        XCTAssertEqual(files, [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    func testNoMatchCharactersInRange() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[a-z].swift"))
        XCTAssertTrue(files.isEmpty)
    }

    func testMatchesMultipleFiles() {
        let expectedFiles: Set = [
            mockPath.stringByAppendingPathComponent("Level0.swift"),
            mockPath.stringByAppendingPathComponent("Directory.swift"),
        ]

        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("*.swift"))
        XCTAssertEqual(files.sorted(), expectedFiles.sorted())
    }

    func testMatchesNestedDirectory() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level1/*.swift"))
        XCTAssertEqual(files, [mockPath.stringByAppendingPathComponent("Level1/Level1.swift")])
    }

    func testGlobstarSupport() {
        let expectedFiles = Set(
            [
                "Directory.swift",
                "Directory.swift/DirectoryLevel1.swift",
                "Level0.swift",
                "Level1/Level1.swift",
                "Level1/Level2/Level2.swift",
                "Level1/Level2/Level3/Level3.swift",
                "NestedConfig/Test/Main.swift",
                "NestedConfig/Test/Sub/Sub.swift",
            ].map(mockPath.stringByAppendingPathComponent)
        )

        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("**/*.swift"))
        XCTAssertEqual(files.sorted(), expectedFiles.sorted())
    }

    func testCreateFilenameMatchers() {
        func assertGlobMatch(root: String, pattern: String, filename: String) {
            let matchers = Glob.createFilenameMatchers(root: root, pattern: pattern)
            XCTAssert(matchers.anyMatch(filename: filename))
        }

        assertGlobMatch(root: "/a/b/", pattern: "c/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "/a", pattern: "**/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "/a", pattern: "**/*.swift", filename: "/a/b.swift")
        assertGlobMatch(root: "", pattern: "**/*.swift", filename: "/a/b.swift")
        assertGlobMatch(root: "", pattern: "a/**/b.swift", filename: "a/b.swift")
        assertGlobMatch(root: "", pattern: "a/**/b.swift", filename: "a/c/b.swift")
        assertGlobMatch(root: "", pattern: "**/*.swift", filename: "a.swift")
        assertGlobMatch(root: "", pattern: "a/**/*.swift", filename: "a/b/c.swift")
        assertGlobMatch(root: "", pattern: "a/**/*.swift", filename: "a/b.swift")
        assertGlobMatch(root: "/a/b", pattern: "/a/b/c/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "/a/", pattern: "/a/b/c/*.swift", filename: "/a/b/c/d.swift")

        assertGlobMatch(root: "", pattern: "/a/b/c", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "", pattern: "/a/b/c/", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "", pattern: "/a/b/c/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "", pattern: "/d.swift/*.swift", filename: "/d.swift/e.swift")
        assertGlobMatch(root: "", pattern: "/a/**", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "", pattern: "**/*Test*", filename: "/a/b/c/MyTest2.swift")
        assertGlobMatch(root: "", pattern: "**/*Test*", filename: "/a/b/MyTests/c.swift")
    }
}
