import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

private let fixturesDirectory = #file.bridge()
    .deletingLastPathComponent.bridge()
    .appendingPathComponent("Resources/FileNameRuleFixtures")

class FileNameRuleTests: XCTestCase {
    private func validate(fileName: String, excludedOverride: [String]? = nil,
                          prefixPattern: String? = nil, suffixPattern: String? = nil,
                          nestedTypeSeparator: String? = nil) throws -> [StyleViolation] {
        let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
        let rule: FileNameRule
        if let excluded = excludedOverride {
            rule = try FileNameRule(configuration: ["excluded": excluded])
        } else if let prefixPattern = prefixPattern, let suffixPattern = suffixPattern {
            rule = try FileNameRule(configuration: ["prefix_pattern": prefixPattern, "suffix_pattern": suffixPattern])
        } else if let prefixPattern = prefixPattern {
            rule = try FileNameRule(configuration: ["prefix_pattern": prefixPattern])
        } else if let suffixPattern = suffixPattern {
            rule = try FileNameRule(configuration: ["suffix_pattern": suffixPattern])
        } else if let nestedTypeSeparator = nestedTypeSeparator {
            rule = try FileNameRule(configuration: ["nested_type_separator": nestedTypeSeparator])
        } else {
            rule = FileNameRule()
        }

        return rule.validate(file: file)
    }

    func testMainDoesntTrigger() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "main.swift").isEmpty)
    }

    func testLinuxMainDoesntTrigger() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "LinuxMain.swift").isEmpty)
    }

    func testClassNameDoesntTrigger() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "MyClass.swift").isEmpty)
    }

    func testStructNameDoesntTrigger() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "MyStruct.swift").isEmpty)
    }

    func testExtensionNameDoesntTrigger() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "NSString+Extension.swift").isEmpty)
    }

    func testNestedExtensionDoesntTrigger() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "Notification.Name+Extension.swift").isEmpty)
    }

    func testNestedTypeSeparatorDoesntTrigger() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "NotificationName+Extension.swift", nestedTypeSeparator: "").isEmpty)
        XCTAssert(try validate(fileName: "Notification__Name+Extension.swift", nestedTypeSeparator: "__").isEmpty)
    }

    func testWrongNestedTypeSeparatorDoesTrigger() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try !validate(fileName: "Notification__Name+Extension.swift", nestedTypeSeparator: ".").isEmpty)
        XCTAssert(try !validate(fileName: "NotificationName+Extension.swift", nestedTypeSeparator: "__").isEmpty)
    }

    func testMisspelledNameDoesTrigger() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssertEqual(try validate(fileName: "MyStructf.swift").count, 1)
    }

    func testMisspelledNameDoesntTriggerWithOverride() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "MyStructf.swift", excludedOverride: ["MyStructf.swift"]).isEmpty)
    }

    func testMainDoesTriggerWithoutOverride() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssertEqual(try validate(fileName: "main.swift", excludedOverride: []).count, 1)
    }

    func testCustomSuffixPattern() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "BoolExtension.swift", suffixPattern: "Extensions?").isEmpty)
        XCTAssert(try validate(fileName: "BoolExtensions.swift", suffixPattern: "Extensions?").isEmpty)
        XCTAssert(try validate(fileName: "BoolExtensionTests.swift", suffixPattern: "Extensions?|\\+.*").isEmpty)
    }

    func testCustomPrefixPattern() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(try validate(fileName: "ExtensionBool.swift", prefixPattern: "Extensions?").isEmpty)
        XCTAssert(try validate(fileName: "ExtensionsBool.swift", prefixPattern: "Extensions?").isEmpty)
    }

    func testCustomPrefixAndSuffixPatterns() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        XCTAssert(
            try validate(
                fileName: "SLBoolExtension.swift",
                prefixPattern: "SL",
                suffixPattern: "Extensions?|\\+.*"
            ).isEmpty
        )

        XCTAssert(
            try validate(
                fileName: "ExtensionBool+SwiftLint.swift",
                prefixPattern: "Extensions?",
                suffixPattern: "Extensions?|\\+.*"
            ).isEmpty
        )
    }
}
