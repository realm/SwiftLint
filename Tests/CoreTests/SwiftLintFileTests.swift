import SwiftLintFramework
import TestHelpers
import XCTest

@testable import SwiftLintCore

final class SwiftLintFileTests: SwiftLintTestCase {
    private let tempFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

    override func setUp() async throws {
        try await super.setUp()
        try Data("let i = 2".utf8).write(to: tempFile)
    }

    override func tearDown() async throws {
        try FileManager.default.removeItem(at: tempFile)
        try await super.tearDown()
    }

    func testFileFromStringUpdate() {
        let file = SwiftLintFile(contents: "let i = 1")

        XCTAssertTrue(file.isVirtual)
        XCTAssertNil(file.path)
        XCTAssertEqual(file.contents, "let i = 1")

        file.write("let j = 2")

        XCTAssertEqual(file.contents, "let j = 2")

        file.append("2")

        XCTAssertEqual(file.contents, "let j = 22")
    }

    func testFileUpdate() {
        let file = SwiftLintFile(path: tempFile)!

        XCTAssertFalse(file.isVirtual)
        XCTAssertNotNil(file.path)
        XCTAssertEqual(file.contents, "let i = 2")

        file.write("let j = 2")

        XCTAssertEqual(file.contents, "let j = 2")
        XCTAssertEqual(FileManager.default.contents(atPath: tempFile.path), Data("let j = 2".utf8))

        file.append("2")

        XCTAssertEqual(file.contents, "let j = 22")
        XCTAssertEqual(FileManager.default.contents(atPath: tempFile.path), Data("let j = 22".utf8))
    }

    func testFileNotTouchedIfNothingAppended() {
        let file = SwiftLintFile(path: tempFile)!
        let initialModificationData = FileManager.default.modificationDate(forFileAtPath: tempFile)

        file.append("")

        XCTAssertEqual(initialModificationData, FileManager.default.modificationDate(forFileAtPath: tempFile))
    }

    func testFileNotTouchedIfNothingNewWritten() {
        let file = SwiftLintFile(path: tempFile)!
        let initialModificationData = FileManager.default.modificationDate(forFileAtPath: tempFile)

        file.write("let i = 2")

        XCTAssertEqual(initialModificationData, FileManager.default.modificationDate(forFileAtPath: tempFile))
    }
}
