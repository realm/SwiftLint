@testable import SwiftLintFramework
import XCTest

private let fixturesDirectory = "\(TestResources.path)/FileNameRuleFixtures"

class FileNameRuleTests: XCTestCase {
    private func validate(fileName: String, excludedOverride: [String]? = nil,
                          prefixPattern: String? = nil, suffixPattern: String? = nil,
                          nestedTypeSeparator: String? = nil) async throws -> [StyleViolation] {
        let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
        let rule: FileNameRule
        if let excluded = excludedOverride {
            rule = try FileNameRule(configuration: ["excluded": excluded])
        } else if let prefixPattern, let suffixPattern {
            rule = try FileNameRule(configuration: ["prefix_pattern": prefixPattern, "suffix_pattern": suffixPattern])
        } else if let prefixPattern {
            rule = try FileNameRule(configuration: ["prefix_pattern": prefixPattern])
        } else if let suffixPattern {
            rule = try FileNameRule(configuration: ["suffix_pattern": suffixPattern])
        } else if let nestedTypeSeparator {
            rule = try FileNameRule(configuration: ["nested_type_separator": nestedTypeSeparator])
        } else {
            rule = FileNameRule()
        }

        return try await rule.validate(file: file)
    }

    func testMainDoesntTrigger() async throws {
        let violations = try await validate(fileName: "main.swift")
        XCTAssert(violations.isEmpty)
    }

    func testLinuxMainDoesntTrigger() async throws {
        let violations = try await validate(fileName: "LinuxMain.swift")
        XCTAssert(violations.isEmpty)
    }

    func testClassNameDoesntTrigger() async throws {
        let violations = try await validate(fileName: "MyClass.swift")
        XCTAssert(violations.isEmpty)
    }

    func testStructNameDoesntTrigger() async throws {
        let violations = try await validate(fileName: "MyStruct.swift")
        XCTAssert(violations.isEmpty)
    }

    func testExtensionNameDoesntTrigger() async throws {
        let violations = try await validate(fileName: "NSString+Extension.swift")
        XCTAssert(violations.isEmpty)
    }

    func testNestedExtensionDoesntTrigger() async throws {
        let violations = try await validate(fileName: "Notification.Name+Extension.swift")
        XCTAssert(violations.isEmpty)
    }

    func testNestedTypeSeparatorDoesntTrigger() async throws {
        do {
            let violations = try await validate(fileName: "NotificationName+Extension.swift",
                                                nestedTypeSeparator: "")
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "Notification__Name+Extension.swift",
                                                nestedTypeSeparator: "__")
            XCTAssert(violations.isEmpty)
        }
    }

    func testWrongNestedTypeSeparatorDoesTrigger() async throws {
        do {
            let violations = try await validate(fileName: "Notification__Name+Extension.swift",
                                                nestedTypeSeparator: ".")
            XCTAssert(!violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "NotificationName+Extension.swift",
                                                nestedTypeSeparator: "__")
            XCTAssert(!violations.isEmpty)
        }
    }

    func testMisspelledNameDoesTrigger() async throws {
        let violations = try await validate(fileName: "MyStructf.swift")
        XCTAssertEqual(violations.count, 1)
    }

    func testMisspelledNameDoesntTriggerWithOverride() async throws {
        let violations = try await validate(fileName: "MyStructf.swift", excludedOverride: ["MyStructf.swift"])
        XCTAssert(violations.isEmpty)
    }

    func testMainDoesTriggerWithoutOverride() async throws {
        let violations = try await validate(fileName: "main.swift", excludedOverride: [])
        XCTAssertEqual(violations.count, 1)
    }

    func testCustomSuffixPattern() async throws {
        do {
            let violations = try await validate(fileName: "BoolExtension.swift", suffixPattern: "Extensions?")
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "BoolExtensions.swift", suffixPattern: "Extensions?")
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "BoolExtensionTests.swift",
                                                suffixPattern: "Extensions?|\\+.*")
            XCTAssert(violations.isEmpty)
        }
    }

    func testCustomPrefixPattern() async throws {
        do {
            let violations = try await validate(fileName: "ExtensionBool.swift", prefixPattern: "Extensions?")
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "ExtensionsBool.swift", prefixPattern: "Extensions?")
            XCTAssert(violations.isEmpty)
        }
    }

    func testCustomPrefixAndSuffixPatterns() async throws {
        do {
            let violations = try await validate(
                fileName: "SLBoolExtension.swift",
                prefixPattern: "SL",
                suffixPattern: "Extensions?|\\+.*"
            )
            XCTAssertEqual(violations, [])
        }

        do {
            let violations = try await validate(
                fileName: "ExtensionBool+SwiftLint.swift",
                prefixPattern: "Extensions?",
                suffixPattern: "Extensions?|\\+.*"
            )
            XCTAssertEqual(violations, [])
        }
    }
}
