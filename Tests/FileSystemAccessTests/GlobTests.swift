import TestHelpers
import Testing

@testable import SwiftLintFramework

extension FileSystemAccessTestSuite.GlobTests {
    private var mockPath: String {
        TestResources.path().stringByAppendingPathComponent("ProjectMock")
    }

    @Test
    func nonExistingDirectory() {
        #expect(Glob.resolveGlob("./bar/**").isEmpty)
    }

    @Test
    func onlyGlobForWildcard() {
        let files = Glob.resolveGlob("foo/bar.swift")
        #expect(files == ["foo/bar.swift"])
    }

    @Test
    func noMatchReturnsEmpty() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("NoFile*.swift"))
        #expect(files.isEmpty)
    }

    @Test
    func matchesFiles() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level*.swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    @Test
    func matchesSingleCharacter() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level?.swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    @Test
    func matchesOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[01].swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    @Test
    func noMatchOneCharacterInBracket() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[ab].swift"))
        #expect(files.isEmpty)
    }

    @Test
    func matchesCharacterInRange() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[0-9].swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    @Test
    func noMatchCharactersInRange() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level[a-z].swift"))
        #expect(files.isEmpty)
    }

    @Test
    func matchesMultipleFiles() {
        let expectedFiles: Set = [
            mockPath.stringByAppendingPathComponent("Level0.swift"),
            mockPath.stringByAppendingPathComponent("Directory.swift"),
        ]

        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("*.swift"))
        #expect(files.sorted() == expectedFiles.sorted())
    }

    @Test
    func matchesNestedDirectory() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level1/*.swift"))
        #expect(files == [mockPath.stringByAppendingPathComponent("Level1/Level1.swift")])
    }

    @Test
    func globstarSupport() {
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
