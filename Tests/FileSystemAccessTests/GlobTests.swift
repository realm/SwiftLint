import FilenameMatcher
import Foundation
import TestHelpers
import Testing

@testable import SwiftLintFramework

private let mockPath = Constants.Dir.level0

@Suite(.rulesRegistered, .workingDirectory(mockPath))
struct GlobTests {
   @Test
    func nonExistingDirectory() {
        #expect(Glob.resolveGlob("./bar/**".url()).isEmpty)
    }

    @Test
    func onlyGlobForWildcard() {
        let files = Glob.resolveGlob("foo/bar.swift".url())
        #expect(files == ["foo/bar.swift".url()])
    }

    @Test
    func noMatchReturnsEmpty() {
        let files = Glob.resolveGlob(mockPath.appending(path: "NoFile*.swift"))
        #expect(files.isEmpty)
    }

    @Test
    func matchesFiles() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level*.swift"))
        #expect(files == [mockPath.appending(path: "Level0.swift")])
    }

    @Test
    func matchesSingleCharacter() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level?.swift"))
        #expect(files == [mockPath.appending(path: "Level0.swift")])
    }

    #if !os(Windows)
    @Test
    func matchesOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level[01].swift"))
        #expect(files == [mockPath.appending(path: "Level0.swift")])
    }

    @Test
    func noMatchOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level[ab].swift"))
        #expect(files.isEmpty)
    }

    @Test
    func matchesCharacterInRange() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level[0-9].swift"))
        #expect(files == [mockPath.appending(path: "Level0.swift")])
    }

    @Test
    func noMatchCharactersInRange() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level[a-z].swift"))
        #expect(files.isEmpty)
    }
    #endif

    @Test
    func matchesMultipleFiles() {
        let expectedFiles = [
            mockPath.appending(path: "Level0.swift"),
            mockPath.appending(path: "Directory.swift/"),
        ]

        let files = Glob.resolveGlob(mockPath.appending(path: "*.swift"))
        AssertEqualInAnyOrder(files, expectedFiles)
    }

    @Test
    func matchesNestedDirectory() {
        let files = Glob.resolveGlob(mockPath.appending(path: "Level1/*.swift"))
        #expect(files == [mockPath.appending(path: "Level1/Level1.swift")])
    }

    @Test
    func globstarSupport() {
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
        AssertEqualInAnyOrder(files, expectedFiles)
    }

    @Test
    func createFilenameMatchers() {
        func assertGlobMatch(pattern: String, filename: String, line: Int = #line) {
            #if os(Windows)
            guard let driveLetter = ProcessInfo.processInfo.environment["SystemDrive"] else {
                return
            }
            var resolvedPattern = driveLetter + pattern
            var resolvedFilename = driveLetter + filename
            #else
            let resolvedPattern = pattern
            let resolvedFilename = filename
            #endif
            let matchers = Glob.createFilenameMatchers(pattern: resolvedPattern)
            #expect(
                matchers.anyMatch(filename: resolvedFilename),
                sourceLocation: SourceLocation(fileID: #fileID, filePath: #filePath, line: line, column: 1)
            )
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
    private func AssertEqualInAnyOrder(_ lhs: [URL], _ rhs: [URL], line: Int = #line) {
        func compare(lhs: URL, rhs: URL) -> Bool {
            lhs.path < rhs.path
        }
        #expect(
            lhs.sorted(by: compare) == rhs.sorted(by: compare),
            sourceLocation: SourceLocation(fileID: #fileID, filePath: #filePath, line: line, column: 1)
        )
    }
}
