@testable import SwiftLintFramework
import TestHelpers
import Testing

@Suite
struct GlobTests {
    private var mockPath: String {
        TestResources.path().stringByAppendingPathComponent("ProjectMock")
    }

    @Test
    func testNonExistingDirectory() {
        #expect(Glob.resolveGlob("./bar/**").isEmpty)
    }

    @Test
    func testOnlyGlobForWildcard() {
        let files = Glob.resolveGlob("foo/bar.swift")
        #expect(files == ["foo/bar.swift"])
    }

    @Test
    func testNoMatchReturnsEmpty() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("NoFile*.swift"))
        #expect(files.isEmpty)
    }

    @Test
    func testMatchesFiles() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level*.swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    @Test
    func testMatchesSingleCharacter() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level?.swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    @Test
    func testMatchesOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[01].swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    @Test
    func testNoMatchOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[ab].swift"))
        #expect(files.isEmpty)
    }

    @Test
    func testMatchesCharacterInRange() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[0-9].swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    @Test
    func testNoMatchCharactersInRange() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[a-z].swift"))
        #expect(files.isEmpty)
    }

    @Test
    func testMatchesMultipleFiles() {
        let expectedFiles: Set = [
            mockPath.stringByAppendingPathComponent("Level0.swift"),
            mockPath.stringByAppendingPathComponent("Directory.swift"),
        ]

        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("*.swift"))
        #expect(files.sorted() == expectedFiles.sorted())
    }

    @Test
    func testMatchesNestedDirectory() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level1/*.swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level1/Level1.swift")])
    }

    @Test
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
        #expect(files.sorted() == expectedFiles.sorted())
    }
}
