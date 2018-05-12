import SourceKittenFramework
import SwiftLintFramework
import XCTest

private let fixturesDirectory = #file.bridge()
    .deletingLastPathComponent.bridge()
    .appendingPathComponent("Resources/FileNameRuleFixtures")

class FileNameRuleTests: XCTestCase {
    private func validate(fileName: String, excludedOverride: [String]? = nil) throws -> [StyleViolation] {
        let file = File(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
        let rule: FileNameRule
        if let excluded = excludedOverride {
            rule = try FileNameRule(configuration: ["excluded": excluded])
        } else {
            rule = FileNameRule()
        }
        return rule.validate(file: file)
    }

    func testMainDoesntTrigger() {
        XCTAssert(try validate(fileName: "main.swift").isEmpty)
    }

    func testLinuxMainDoesntTrigger() {
        XCTAssert(try validate(fileName: "LinuxMain.swift").isEmpty)
    }

    func testClassNameDoesntTrigger() {
        XCTAssert(try validate(fileName: "MyClass.swift").isEmpty)
    }

    func testStructNameDoesntTrigger() {
        XCTAssert(try validate(fileName: "MyStruct.swift").isEmpty)
    }

    func testExtensionNameDoesntTrigger() {
        XCTAssert(try validate(fileName: "NSString+Extension.swift").isEmpty)
    }

    func testMisspelledNameDoesTrigger() {
        XCTAssertEqual(try validate(fileName: "MyStructf.swift").count, 1)
    }

    func testMisspelledNameDoesntTriggerWithOverride() {
        XCTAssert(try validate(fileName: "MyStructf.swift", excludedOverride: ["MyStructf.swift"]).isEmpty)
    }

    func testMainDoesTriggerWithoutOverride() {
        XCTAssertEqual(try validate(fileName: "main.swift", excludedOverride: []).count, 1)
    }
}
