import SourceKittenFramework
@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class FileNameNoSpaceRuleTests: SwiftLintTestCase {
    private func validate(fileName: String, excludedOverride: [String]? = nil) throws -> [StyleViolation] {
        let file = TestResources.path()
            .appending(path: "FileNameNoSpaceRuleFixtures", directoryHint: .isDirectory)
            .appending(path: fileName, directoryHint: .notDirectory)
        let rule =
            if let excluded = excludedOverride {
                try FileNameNoSpaceRule(configuration: ["excluded": excluded])
            } else {
                FileNameNoSpaceRule()
            }
        return rule.validate(file: SwiftLintFile(path: file)!)
    }

    func testFileNameDoesntTrigger() {
        XCTAssert(try validate(fileName: "File.swift").isEmpty)
    }

    func testFileWithSpaceDoesTrigger() {
        XCTAssertEqual(try validate(fileName: "File Name.swift").count, 1)
    }

    func testExtensionNameDoesntTrigger() {
        XCTAssert(try validate(fileName: "File+Extension.swift").isEmpty)
    }

    func testExtensionWithSpaceDoesTrigger() {
        XCTAssertEqual(try validate(fileName: "File+Test Extension.swift").count, 1)
    }

    func testCustomExcludedList() {
        XCTAssert(try validate(fileName: "File+Test Extension.swift",
                               excludedOverride: ["File+Test Extension.swift"]).isEmpty)
    }
}
