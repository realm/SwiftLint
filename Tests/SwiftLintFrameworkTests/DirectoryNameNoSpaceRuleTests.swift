import SourceKittenFramework
import SwiftLintFramework
import XCTest

private let fixturesDirectory = #file.bridge()
    .deletingLastPathComponent.bridge()
    .appendingPathComponent("Resources/DirectoryNameNoSpaceRuleFixtures")

class DirectoryNameNoSpaceRuleTests: XCTestCase {
    private func validate(fileName: String, excludedOverride: [String]? = nil,
                          parentDirectory: String? = nil) throws -> [StyleViolation] {
        let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
        let rule: DirectoryNameNoSpaceRule
        if let excluded = excludedOverride {
            rule = try DirectoryNameNoSpaceRule(configuration: ["excluded": excluded])
        } else if let parentDirectory = parentDirectory {
            rule = try DirectoryNameNoSpaceRule(configuration: ["parent_directory": parentDirectory])
        } else {
            rule = DirectoryNameNoSpaceRule()
        }

        return rule.validate(file: file)
    }

    func testDirectoryDoesNotTrigger() {
        XCTAssert(try validate(fileName: "DirectoryName/File.swift").isEmpty)
    }

    func testDirectoryNameDoesTrigger() {
        XCTAssertEqual(try validate(fileName: "Directory Name/File.swift").count, 1)
        XCTAssertEqual(try validate(fileName: "Directory Name/SubdirectoryName/File.swift").count, 1)
    }

    func testSubdirectoryNameDoesNotTrigger() {
        XCTAssert(try validate(fileName: "DirectoryName/SubdirectoryName/File.swift").isEmpty)
    }

    func testSubdirectoryNameDoesTrigger() {
        XCTAssertEqual(try validate(fileName: "DirectoryName/Subdirectory Name/File.swift").count, 1)
    }

    func testFileNameDoesNotTrigger() {
        XCTAssert(try validate(fileName: "DirectoryName/SubdirectoryName/File Name.swift").isEmpty)
    }

    func testCustomParentDirectory() {
        XCTAssert(try validate(fileName: "Directory Name/SubdirectoryName/File.swift",
                               parentDirectory: "SubdirectoryName").isEmpty)
    }

    func testCustomExcluded() {
        XCTAssert(try validate(fileName: "Directory Name/SubdirectoryName/File.swift",
                               excludedOverride: ["Directory Name"]).isEmpty)
        XCTAssert(try validate(fileName: "Directory Name/Subdirectory Name/File.swift",
                               excludedOverride: ["Directory Name"]).isEmpty)
    }
}
