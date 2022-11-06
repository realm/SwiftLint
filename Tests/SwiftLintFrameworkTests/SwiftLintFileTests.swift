@testable import SwiftLintCore
import XCTest

class SwiftLintFileTests: SwiftLintTestCase {
    private let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    override func setUp() async throws {
        try await super.setUp()
        try "let i = 2".data(using: .utf8)!.write(to: tempFile)
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

    func testFileUpdate() throws {
        let file = SwiftLintFile(path: tempFile.path)!

        XCTAssertFalse(file.isVirtual)
        XCTAssertNotNil(file.path)
        XCTAssertEqual(file.contents, "let i = 2")

        file.write("let j = 2")

        XCTAssertEqual(file.contents, "let j = 2")
        XCTAssertEqual(FileManager.default.contents(atPath: tempFile.path), "let j = 2".data(using: .utf8))

        file.append("2")

        XCTAssertEqual(file.contents, "let j = 22")
        XCTAssertEqual(FileManager.default.contents(atPath: tempFile.path), "let j = 22".data(using: .utf8))
    }

    func testFileNotTouchedIfNothingAppended() throws {
        let file = SwiftLintFile(path: tempFile.path)!
        let initialModificationData = FileManager.default.modificationDate(forFileAtPath: tempFile.path)

        file.append("")

        XCTAssertEqual(initialModificationData, FileManager.default.modificationDate(forFileAtPath: tempFile.path))
    }

    func testFileNotTouchedIfNothingNewWritten() throws {
        let file = SwiftLintFile(path: tempFile.path)!
        let initialModificationData = FileManager.default.modificationDate(forFileAtPath: tempFile.path)

        file.write("let i = 2")

        XCTAssertEqual(initialModificationData, FileManager.default.modificationDate(forFileAtPath: tempFile.path))
    }
}
