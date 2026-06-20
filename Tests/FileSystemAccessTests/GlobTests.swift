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
            guard let driveLetter = ProcessInfo.processInfo.environment["SystemDrive"] else {
                XCTFail("Cannot retrieve %SystemDrive% environment variable")
                return
            }
            var pattern = driveLetter + pattern
            var filename = driveLetter + filename
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

    // swiftlint:disable:next function_body_length
    func testGlobstarToleratesUnreadableSubdirectory() throws {
#if !os(Windows)
        try XCTSkipIf(
            getuid() == 0,
            "Permission-bit tests cannot exercise the tolerance fix when running as root."
        )
#endif

        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(
            "SwiftLintGlobTolerance-\(UUID().uuidString)"
        )
        let unreadableDir = root.appending(path: "a/b/c")
        let openDir = root.appending(path: "a/x")
        try fileManager.createDirectory(at: unreadableDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: openDir, withIntermediateDirectories: true)

        let paths = [
            root.appending(path: "top.swift"),
            root.appending(path: "a/inA.swift"),
            root.appending(path: "a/b/inB.swift"),
            unreadableDir.appending(path: "inC.swift"),
            openDir.appending(path: "inX.swift"),
        ]

        for path in paths {
            try "let x = 1".write(to: path, atomically: true, encoding: .utf8)
        }

#if os(Windows)
        let username = ProcessInfo.processInfo.environment["USERNAME"] ?? ""
        try XCTSkipIf(username.isEmpty, "Cannot determine current Windows username to set ACLs.")

        // Deny read/list permissions for this directory to trigger traversal errors.
        let icaclsPath = URL(filePath: "C:/Windows/System32/icacls.exe", directoryHint: .notDirectory)
        func runIcacls(_ arguments: [String]) throws -> Int32 {
            let process = Process()
            process.executableURL = icaclsPath
            process.arguments = arguments
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        }

        let denyExitCode = try runIcacls([
            unreadableDir.filepath,
            "/deny",
            "\(username):(RX)",
        ])
        try XCTSkipIf(denyExitCode != 0, "Failed to make test directory unreadable on Windows.")

        defer {
            _ = try? runIcacls([
                unreadableDir.filepath,
                "/remove:d",
                username,
            ])
            try? fileManager.removeItem(atPath: root.filepath)
        }

        let canStillAccess = (try? fileManager.contentsOfDirectory(atPath: unreadableDir.filepath)) != nil
        try XCTSkipIf(
            canStillAccess,
            "User has elevated privileges allowing bypass of deny ACLs; cannot test tolerance on Windows runners."
        )
#else
        // Make `a/b/c` unreadable. This is what previously made
        // `subpathsOfDirectory(atPath:)` throw and drop every directory it had
        // collected so far, leaving only the search root globbed.
        try fileManager.setAttributes([.posixPermissions: 0o000], ofItemAtPath: unreadableDir.filepath)
        defer {
            // Restore permissions so cleanup can remove the tree even if the test fails.
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: unreadableDir.filepath)
            try? fileManager.removeItem(atPath: root.filepath)
        }
#endif

        let matches = Glob.resolveGlob(root.appending(components: "**", "*.swift"))

        // Siblings of the unreadable subtree must still resolve. Without the fix only top.swift
        // (the search-root's own pattern) would have matched.
        XCTAssertTrue(matches.contains { $0.lastPathComponent == "top.swift" }, "top.swift missing")
        XCTAssertTrue(
            matches.contains { $0.path.hasSuffix("/a/inA.swift") }, "a/inA.swift missing — tolerance regressed"
        )
        XCTAssertTrue(
            matches.contains { $0.path.hasSuffix("/a/b/inB.swift") }, "a/b/inB.swift missing — tolerance regressed"
        )
        XCTAssertTrue(
            matches.contains { $0.path.hasSuffix("/a/x/inX.swift") }, "a/x/inX.swift missing — tolerance regressed"
        )

        // The unreadable subtree is genuinely inaccessible.
        XCTAssertFalse(
            matches.contains { $0.lastPathComponent == "inC.swift" }, "inC.swift should not be reachable"
        )
    }
}
