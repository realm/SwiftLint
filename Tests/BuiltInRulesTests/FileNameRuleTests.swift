@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

private let fixturesDirectory =
    URL(fileURLWithPath: TestResources.path()).appendingPathComponent("FileNameRuleFixtures").filepath

final class FileNameRuleTests: SwiftLintTestCase {
    private func validate(fileName: String,
                          excluded: [String]? = nil,
                          excludedPaths: [String]? = nil,
                          prefixPattern: String? = nil,
                          suffixPattern: String? = nil,
                          nestedTypeSeparator: String? = nil,
                          requireFullyQualifiedNames: Bool = false) throws -> [StyleViolation] {
        let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!

        var configuration = [String: Any]()

        if let excluded {
            configuration["excluded"] = excluded
        }
        if let excludedPaths {
            configuration["excluded_paths"] = excludedPaths
        }
        if let prefixPattern {
            configuration["prefix_pattern"] = prefixPattern
        }
        if let suffixPattern {
            configuration["suffix_pattern"] = suffixPattern
        }
        if let nestedTypeSeparator {
            configuration["nested_type_separator"] = nestedTypeSeparator
        }
        if requireFullyQualifiedNames {
            configuration["require_fully_qualified_names"] = requireFullyQualifiedNames
        }

        let rule = try FileNameRule(configuration: configuration)

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

    func testMacroNameDoesntTrigger() {
        XCTAssert(try validate(fileName: "MyMacro.swift").isEmpty)
    }

    func testExtensionNameDoesntTrigger() {
        XCTAssert(try validate(fileName: "NSString+Extension.swift").isEmpty)
    }

    func testNestedExtensionDoesntTrigger() {
        XCTAssert(try validate(fileName: "Notification.Name+Extension.swift").isEmpty)
    }

    func testNestedTypeDoesntTrigger() {
        XCTAssert(try validate(fileName: "Nested.MyType.swift").isEmpty)
    }

    func testMultipleLevelsDeeplyNestedTypeDoesntTrigger() {
        XCTAssert(try validate(fileName: "Multiple.Levels.Deeply.Nested.MyType.swift").isEmpty)
    }

    func testNestedTypeNotFullyQualifiedDoesntTrigger() {
        XCTAssert(try validate(fileName: "MyType.swift").isEmpty)
    }

    func testNestedTypeNotFullyQualifiedDoesTriggerWithOverride() {
        XCTAssert(try validate(fileName: "MyType.swift", requireFullyQualifiedNames: true).isNotEmpty)
    }

    func testNestedTypeSeparatorDoesntTrigger() {
        XCTAssert(try validate(fileName: "NotificationName+Extension.swift", nestedTypeSeparator: "").isEmpty)
        XCTAssert(try validate(fileName: "Notification__Name+Extension.swift", nestedTypeSeparator: "__").isEmpty)
    }

    func testWrongNestedTypeSeparatorDoesTrigger() {
        XCTAssert(try validate(fileName: "Notification__Name+Extension.swift", nestedTypeSeparator: ".").isNotEmpty)
        XCTAssert(try validate(fileName: "NotificationName+Extension.swift", nestedTypeSeparator: "__").isNotEmpty)
    }

    func testMisspelledNameDoesTrigger() {
        XCTAssertEqual(try validate(fileName: "MyStructf.swift").count, 1)
    }

    func testMisspelledNameDoesntTriggerWithOverride() {
        XCTAssert(try validate(fileName: "MyStructf.swift", excluded: ["MyStructf.swift"]).isEmpty)
    }

    func testMainDoesTriggerWithoutOverride() {
        XCTAssertEqual(try validate(fileName: "main.swift", excluded: []).count, 1)
    }

    func testCustomSuffixPattern() {
        XCTAssert(try validate(fileName: "BoolExtension.swift", suffixPattern: "Extensions?").isEmpty)
        XCTAssert(try validate(fileName: "BoolExtensions.swift", suffixPattern: "Extensions?").isEmpty)
        XCTAssert(try validate(fileName: "BoolExtensionTests.swift", suffixPattern: "Extensions?|\\+.*").isEmpty)
    }

    func testCustomPrefixPattern() {
        XCTAssert(try validate(fileName: "ExtensionBool.swift", prefixPattern: "Extensions?").isEmpty)
        XCTAssert(try validate(fileName: "ExtensionsBool.swift", prefixPattern: "Extensions?").isEmpty)
    }

    func testCustomPrefixAndSuffixPatterns() {
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

    func testExcludedDoesntSupportRegex() {
        XCTAssert(
            try validate(
                fileName: "main.swift",
                excluded: [".*"]
            ).isNotEmpty
        )
    }

    func testExcludedPathPatternsSupportRegex() {
        XCTAssert(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*"]
            ).isEmpty
        )

        XCTAssert(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*.swift"]
            ).isEmpty
        )

        XCTAssert(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [#".*[\\/]FileNameRuleFixtures[\\/].*"#]
            ).isEmpty
        )
    }

    func testExcludedPathPatternsWithRegexDoesntMatch() {
        XCTAssert(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [#".*[\\/]OtherFolder[\\/].*"#, "MAIN\\.swift"]
            ).isNotEmpty
        )
    }

    func testInvalidRegex() {
        XCTAssertThrowsError(
            try validate(
                fileName: "NSString+Extension.swift",
                excluded: [],
                excludedPaths: ["("],
                prefixPattern: "",
                suffixPattern: ""
            )
        )
    }

    func testExcludedPathPatternsWithMultipleRegexs() {
        XCTAssertThrowsError(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [#"[\\/]FileNameRuleFixtures[\\/].*"#, "("]
            )
        )

        XCTAssertThrowsError(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [#"[\\/]FileNameRuleFixtures[\\/].*"#, "(", ".*.swift"]
            )
        )
    }
}
