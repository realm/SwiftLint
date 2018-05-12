import SourceKittenFramework
import SwiftLintFramework
import XCTest

private let fixturesDirectory = #file.bridge()
    .deletingLastPathComponent.bridge()
    .appendingPathComponent("Resources/FileNameRuleFixtures")

class FileNameRuleTests: XCTestCase {
    private func validate(fileName: String, excludedOverride: [String]? = nil) -> [StyleViolation] {
        let file = File(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
        let rule: FileNameRule
        if let excluded = excludedOverride {
            rule = try! FileNameRule(configuration: ["excluded": excluded])
        } else {
            rule = FileNameRule()
        }
        return rule.validate(file: file)
    }

    func testMainDoesntTrigger() {
        XCTAssert(validate(fileName: "main.swift").isEmpty)
    }

    func testLinuxMainDoesntTrigger() {
        XCTAssert(validate(fileName: "LinuxMain.swift").isEmpty)
    }

    func testClassNameDoesntTrigger() {
        XCTAssert(validate(fileName: "MyClass.swift").isEmpty)
    }

    func testStructNameDoesntTrigger() {
        XCTAssert(validate(fileName: "MyStruct.swift").isEmpty)
    }

    func testExtensionNameDoesntTrigger() {
        XCTAssert(validate(fileName: "NSString+Extension.swift").isEmpty)
    }

    func testMisspelledNameDoesTrigger() {
        XCTAssertEqual(validate(fileName: "MyStructf.swift").count, 1)
    }

    func testMisspelledNameDoesntTriggerWithOverride() {
        XCTAssert(validate(fileName: "MyStructf.swift", excludedOverride: ["MyStructf.swift"]).isEmpty)
    }

    func testMainDoesTriggerWithoutOverride() {
        XCTAssertEqual(validate(fileName: "main.swift", excludedOverride: []).count, 1)
    }
}
