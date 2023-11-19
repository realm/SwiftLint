@testable import SwiftLintFramework
import XCTest

final class GlobTests: SwiftLintTestCase {
    private var mockPath: String {
        testResourcesPath.stringByAppendingPathComponent("ProjectMock")
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

    func testCreateFilenameMatcher() {
        XCTAssert(Glob.createFilenameMatcher(root: "/a/b/", pattern: "c/*.swift").match(filename: "/a/b/c/d.swift"))
        XCTAssert(Glob.createFilenameMatcher(root: "/a", pattern: "**/*.swift").match(filename: "/a/b/c/d.swift"))
        XCTAssert(Glob.createFilenameMatcher(root: "/a/b", pattern: "/a/b/c/*.swift").match(filename: "/a/b/c/d.swift"))
        XCTAssert(Glob.createFilenameMatcher(root: "/a/", pattern: "/a/b/c/*.swift").match(filename: "/a/b/c/d.swift"))

        XCTAssert(Glob.createFilenameMatcher(root: "", pattern: "/a/b/c").match(filename: "/a/b/c/d.swift"))
        XCTAssert(Glob.createFilenameMatcher(root: "", pattern: "/a/b/c/").match(filename: "/a/b/c/d.swift"))
        XCTAssert(Glob.createFilenameMatcher(root: "", pattern: "/a/b/c/*.swift").match(filename: "/a/b/c/d.swift"))
        XCTAssert(Glob.createFilenameMatcher(root: "", pattern: "/d.swift/*.swift").match(filename: "/d.swift/e.swift"))
        XCTAssert(Glob.createFilenameMatcher(root: "", pattern: "/a/**").match(filename: "/a/b/c/d.swift"))

        XCTAssertFalse(Glob.createFilenameMatcher(root: "/a/", pattern: "**/*.swift").match(filename: "/a/b.swift"))
    }
}
