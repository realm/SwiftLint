import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

final class GlobTests: XCTestCase {
    private var mockPath: String {
        return bundlePath.stringByAppendingPathComponent("ProjectMock")
    }

    func testOnlyGlobForWildcard() {
    	let files = Glob.resolveGlobs(in: "foo/bar.swift")
        XCTAssertEqual(files, ["foo/bar.swift"])
    }

    func testNoMatchReturnsEmpty() {
        let files = Glob.resolveGlobs(in: mockPath.stringByAppendingPathComponent("NoFile*.swift"))
        XCTAssertTrue(files.isEmpty)
    }

    func testMatchesFiles() {
        let files = Glob.resolveGlobs(in: mockPath.stringByAppendingPathComponent("Level*.swift"))
        XCTAssertEqual(files, [mockPath.stringByAppendingPathComponent("Level0.swift")])
    }

    func testMatchesMultipleFiles() {
        let expectedFiles: Set = [
            mockPath.stringByAppendingPathComponent("Level0.swift"),
            mockPath.stringByAppendingPathComponent("Directory.swift").appending("/")
        ]

        let files = Glob.resolveGlobs(in: mockPath.stringByAppendingPathComponent("*.swift"))
        XCTAssertEqual(files.count, 2)
        XCTAssertEqual(Set(files), expectedFiles)
    }

    func testMatchesNestedDirectory() {
        let files = Glob.resolveGlobs(in: mockPath.stringByAppendingPathComponent("Level1/*.swift"))
        XCTAssertEqual(files, [mockPath.stringByAppendingPathComponent("Level1/Level1.swift")])
    }
}
