import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

final class GlobTests: XCTestCase {
    private var mockPath: String {
        return testResourcesPath.stringByAppendingPathComponent("ProjectMock")
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

    func testMatchesMultipleFiles() {
        let expectedFiles: Set = [
            mockPath.stringByAppendingPathComponent("Level0.swift"),
            mockPath.stringByAppendingPathComponent("Directory.swift").appending("/")
        ]

        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("*.swift"))
        XCTAssertEqual(files.count, 2)
        XCTAssertEqual(Set(files), expectedFiles)
    }

    func testMatchesNestedDirectory() {
        let files = Glob.resolveGlob(mockPath.stringByAppendingPathComponent("Level1/*.swift"))
        XCTAssertEqual(files, [mockPath.stringByAppendingPathComponent("Level1/Level1.swift")])
    }
}
