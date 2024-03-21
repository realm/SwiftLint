@testable import SwiftLintCore
import XCTest

final class GlobTests: SwiftLintTestCase {
    private var mockPath: String {
        return testResourcesPath.stringByAppendingPathComponent("ProjectMock")
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
            mockPath.stringByAppendingPathComponent("Directory.swift")
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
                "NestedConfig/Test/Sub/Sub.swift"
            ].map(mockPath.stringByAppendingPathComponent)
        )

        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("**/*.swift"))
        XCTAssertEqual(files.sorted(), expectedFiles.sorted())
    }

    func testCreateFilenameMatchers() {
        struct MatcherTest {
            let root: String
            let pattern: String
            let filenames: [String]

            func matchesAll() -> Bool {
                filenames.allSatisfy { name in
                    Glob.createFilenameMatchers(root: root, pattern: pattern).anyMatch(filename: name)
                }
            }

            func matchesNone() -> Bool {
                filenames.allSatisfy { name in
                    !Glob.createFilenameMatchers(root: root, pattern: pattern).anyMatch(filename: name)
                }
            }
        }

        [
            .init(root: "/a/b/", pattern: "c/*.swift", filenames: ["/a/b/c/d.swift"]),
            .init(root: "/a", pattern: "**/*.swift", filenames: ["/a/b/c/d.swift"]),
            .init(root: "/a/b", pattern: "/a/b/c/*.swift", filenames: ["/a/b/c/d.swift"]),
            .init(root: "/a/", pattern: "/a/b/c/*.swift", filenames: ["/a/b/c/d.swift"]),

            .init(root: "", pattern: "/a/b/c", filenames: ["/a/b/c/d.swift"]),
            .init(root: "", pattern: "/a/b/c/", filenames: ["/a/b/c/d.swift"]),
            .init(root: "", pattern: "/a/b/c/*.swift", filenames: ["/a/b/c/d.swift"]),
            .init(root: "", pattern: "/d.swift/*.swift", filenames: ["/d.swift/e.swift"]),
            .init(root: "", pattern: "/a/**", filenames: ["/a/b/c/d.swift"]),
            .init(root: "", pattern: "**/*Test*", filenames: ["/a/b/c/MyTest2.swift", "/a/b/MyTests/c.swift"])
        ].forEach { (test: MatcherTest) in XCTAssert(test.matchesAll()) }

        XCTAssert(MatcherTest(root: "/a/", pattern: "**/*.swift", filenames: ["/a/b.swift"]).matchesNone())
    }
}
