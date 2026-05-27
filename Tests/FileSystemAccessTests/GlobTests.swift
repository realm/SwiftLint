import FilenameMatcher
import TestHelpers
import XCTest

@testable import SwiftLintFramework

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
        func assertGlobMatch(root: String = "", pattern: String, filename: String) {
            let matchers = Glob.createFilenameMatchers(root: root, pattern: pattern)
            XCTAssert(matchers.anyMatch(filename: filename))
        }

        assertGlobMatch(root: "/a/b/", pattern: "c/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "/a", pattern: "**/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "/a", pattern: "**/*.swift", filename: "/a/b.swift")
        assertGlobMatch(root: "/", pattern: "**/*.swift", filename: "/a/b.swift")
        assertGlobMatch(root: "/", pattern: "a/**/b.swift", filename: "/a/b.swift")
        assertGlobMatch(root: "/", pattern: "a/**/b.swift", filename: "/a/c/b.swift")
        assertGlobMatch(root: "/", pattern: "**/*.swift", filename: "/a.swift")
        assertGlobMatch(root: "/", pattern: "a/**/*.swift", filename: "/a/b/c.swift")
        assertGlobMatch(root: "/", pattern: "a/**/*.swift", filename: "/a/b.swift")
        assertGlobMatch(root: "/a/b", pattern: "/a/b/c/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "/a/", pattern: "/a/b/c/*.swift", filename: "/a/b/c/d.swift")

        assertGlobMatch(pattern: "/a/b/c", filename: "/a/b/c/d.swift")
        assertGlobMatch(pattern: "/a/b/c/", filename: "/a/b/c/d.swift")
        assertGlobMatch(pattern: "/a/b/c/*.swift", filename: "/a/b/c/d.swift")
        assertGlobMatch(pattern: "/d.swift/*.swift", filename: "/d.swift/e.swift")
        assertGlobMatch(pattern: "/a/**", filename: "/a/b/c/d.swift")
        assertGlobMatch(root: "/", pattern: "**/*Test*", filename: "/a/b/c/MyTest2.swift")
        assertGlobMatch(root: "/", pattern: "**/*Test*", filename: "/a/b/MyTests/c.swift")
    }

    /// One unreadable subdirectory in the search tree must not cause the entire glob to drop every
    /// nested file. The previous implementation used `subpathsOfDirectory(atPath:)`, which throws
    /// on the first item it cannot access and discards everything collected so far — on a 50k-file
    /// project that left only the search root globbed, silently ignoring all nested files.
    func testGlobstarToleratesUnreadableSubdirectory() throws {
        try XCTSkipIf(
            getuid() == 0,
            "Permission-bit tests cannot exercise the tolerance fix when running as root."
        )

        let fileManager = FileManager.default
        let root = NSTemporaryDirectory().stringByAppendingPathComponent(
            "SwiftLintGlobTolerance-\(UUID().uuidString)"
        )
        let unreadableDir = root.stringByAppendingPathComponent("a/b/c")
        let openDir = root.stringByAppendingPathComponent("a/x")
        try fileManager.createDirectory(atPath: unreadableDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: openDir, withIntermediateDirectories: true)

        for path in [
            root.stringByAppendingPathComponent("top.swift"),
            root.stringByAppendingPathComponent("a/inA.swift"),
            root.stringByAppendingPathComponent("a/b/inB.swift"),
            unreadableDir.stringByAppendingPathComponent("inC.swift"),
            openDir.stringByAppendingPathComponent("inX.swift"),
        ] {
            try "let x = 1".write(toFile: path, atomically: true, encoding: .utf8)
        }

        // Make `a/b/c` unreadable. This is what previously made
        // `subpathsOfDirectory(atPath:)` throw and drop every directory it had
        // collected so far, leaving only the search root globbed.
        try fileManager.setAttributes([.posixPermissions: 0o000], ofItemAtPath: unreadableDir)
        defer {
            // Restore permissions so cleanup can remove the tree even if the test fails.
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: unreadableDir)
            try? fileManager.removeItem(atPath: root)
        }

        let matches = Glob.resolveGlob(root.stringByAppendingPathComponent("**/*.swift"))

        // Siblings of the unreadable subtree must still resolve. Without the fix only top.swift
        // (the search-root's own pattern) would have matched.
        XCTAssertTrue(matches.contains { $0.hasSuffix("/top.swift") }, "top.swift missing")
        XCTAssertTrue(
            matches.contains { $0.hasSuffix("/a/inA.swift") }, "a/inA.swift missing — tolerance regressed"
        )
        XCTAssertTrue(
            matches.contains { $0.hasSuffix("/a/b/inB.swift") }, "a/b/inB.swift missing — tolerance regressed"
        )
        XCTAssertTrue(
            matches.contains { $0.hasSuffix("/a/x/inX.swift") }, "a/x/inX.swift missing — tolerance regressed"
        )

        // The unreadable subtree is genuinely inaccessible.
        XCTAssertFalse(
            matches.contains { $0.hasSuffix("/inC.swift") }, "inC.swift should not be reachable"
        )
    }
}
