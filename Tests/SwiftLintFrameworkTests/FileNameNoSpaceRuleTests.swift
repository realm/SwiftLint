import SourceKittenFramework
@testable import SwiftLintBuiltInRules
import SwiftLintFramework
import XCTest

private let fixturesDirectory = #file.bridge()
    .deletingLastPathComponent.bridge()
    .appendingPathComponent("Resources/FileNameNoSpaceRuleFixtures")

class FileNameNoSpaceRuleTests: SwiftLintTestCase {
    private func validate(fileName: String, excludedOverride: [String]? = nil) throws -> [StyleViolation] {
        let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
        let rule: FileNameNoSpaceRule
        if let excluded = excludedOverride {
            rule = try FileNameNoSpaceRule(configuration: ["excluded": excluded])
        } else {
            rule = FileNameNoSpaceRule()
        }

        return rule.validate(file: file)
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
