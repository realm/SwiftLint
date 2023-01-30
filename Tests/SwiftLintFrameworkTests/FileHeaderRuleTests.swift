@testable import SwiftLintFramework
import XCTest

private let fixturesDirectory = "\(TestResources.path)/FileHeaderRuleFixtures"

class FileHeaderRuleTests: XCTestCase {
    private func validate(fileName: String, using configuration: Any) async throws -> [StyleViolation] {
        let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
        let rule = try FileHeaderRule(configuration: configuration)
        return try await rule.validate(file: file)
    }

    func testFileHeaderWithDefaultConfiguration() async throws {
        try await verifyRule(FileHeaderRule.description, skipCommentTests: true)
    }

    func testFileHeaderWithRequiredString() async throws {
        let nonTriggeringExamples = [
            Example("// **Header"),
            Example("//\n// **Header")
        ]
        let triggeringExamples = [
            Example("↓// Copyright\n"),
            Example("let foo = \"**Header\""),
            Example("let foo = 2 // **Header"),
            Example("let foo = 2\n// **Header"),
            Example("let foo = 2 // **Header")
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["required_string": "**Header"],
                             stringDoesntViolate: false, skipCommentTests: true,
                             testMultiByteOffsets: false, testShebang: false)
    }

    func testFileHeaderWithRequiredPattern() async throws {
        let nonTriggeringExamples = [
            Example("// Copyright © 2016 Realm"),
            Example("//\n// Copyright © 2016 Realm)")
        ]
        let triggeringExamples = [
            Example("↓// Copyright\n"),
            Example("↓// Copyright © foo Realm"),
            Example("↓// Copyright © 2016 MyCompany")
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["required_pattern": "\\d{4} Realm"],
                             stringDoesntViolate: false, skipCommentTests: true,
                             testMultiByteOffsets: false)
    }

    func testFileHeaderWithRequiredStringAndURLComment() async throws {
        let nonTriggeringExamples = [
            Example("/* Check this url: https://github.com/realm/SwiftLint */")
        ]
        let triggeringExamples = [
            Example("/* Check this url: https://github.com/apple/swift */")
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        let config = ["required_string": "/* Check this url: https://github.com/realm/SwiftLint */"]
        try await verifyRule(description, ruleConfiguration: config,
                             stringDoesntViolate: false, skipCommentTests: true,
                             testMultiByteOffsets: false)
    }

    func testFileHeaderWithForbiddenString() async throws {
        let nonTriggeringExamples = [
            Example("// Copyright\n"),
            Example("let foo = \"**All rights reserved.\""),
            Example("let foo = 2 // **All rights reserved."),
            Example("let foo = 2\n// **All rights reserved."),
            Example("let foo = 2 // **All rights reserved.")
        ]
        let triggeringExamples = [
            Example("// ↓**All rights reserved."),
            Example("//\n// ↓**All rights reserved.")
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["forbidden_string": "**All rights reserved."],
                             skipCommentTests: true)
    }

    func testFileHeaderWithForbiddenPattern() async throws {
        let nonTriggeringExamples = [
            Example("// Copyright\n"),
            Example("// FileHeaderRuleTests.m\n"),
            Example("let foo = \"FileHeaderRuleTests.swift\""),
            Example("let foo = 2 // FileHeaderRuleTests.swift."),
            Example("let foo = 2\n // FileHeaderRuleTests.swift.")
        ]
        let triggeringExamples = [
            Example("//↓ FileHeaderRuleTests.swift"),
            Example("//\n//↓ FileHeaderRuleTests.swift")
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["forbidden_pattern": "\\s\\w+\\.swift"],
                             skipCommentTests: true)
    }

    func testFileHeaderWithForbiddenPatternAndDocComment() async throws {
        let nonTriggeringExamples = [
            Example("/// This is great tool with tests.\nclass GreatTool {}"),
            Example("class GreatTool {}")
        ]
        let triggeringExamples = [
            Example("// FileHeaderRule↓Tests.swift"),
            Example("//\n// FileHeaderRule↓Tests.swift")
        ]
        let description = FileHeaderRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["forbidden_pattern": "[tT]ests"],
                             skipCommentTests: true, testMultiByteOffsets: false)
    }

    func testFileHeaderWithRequiredStringUsingFilenamePlaceholder() async throws {
        let configuration = ["required_string": "// SWIFTLINT_CURRENT_FILENAME"]

        // Non triggering tests
        do {
            let violations = try await validate(fileName: "FileNameMatchingSimple.swift", using: configuration)
            XCTAssert(violations.isEmpty)
        }

        // Triggering tests
        do {
            let violations = try await validate(fileName: "FileNameCaseMismatch.swift", using: configuration)
            XCTAssertEqual(violations.count, 1)
        }
        do {
            let violations = try await validate(fileName: "FileNameMismatch.swift", using: configuration)
            XCTAssertEqual(violations.count, 1)
        }
        do {
            let violations = try await validate(fileName: "FileNameMissing.swift", using: configuration)
            XCTAssertEqual(violations.count, 1)
        }
    }

    func testFileHeaderWithForbiddenStringUsingFilenamePlaceholder() async throws {
        let configuration = ["forbidden_string": "// SWIFTLINT_CURRENT_FILENAME"]

        // Non triggering tests
        do {
            let violations = try await validate(fileName: "FileNameCaseMismatch.swift", using: configuration)
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "FileNameMismatch.swift", using: configuration)
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "FileNameMissing.swift", using: configuration)
            XCTAssert(violations.isEmpty)
        }

        // Triggering tests
        do {
            let violations = try await validate(fileName: "FileNameMatchingSimple.swift", using: configuration)
            XCTAssertEqual(violations.count, 1)
        }
    }

    func testFileHeaderWithRequiredPatternUsingFilenamePlaceholder() async throws {
        let configuration1 = ["required_pattern": "// SWIFTLINT_CURRENT_FILENAME\n.*\\d{4}"]
        let configuration2 = ["required_pattern":
            "// Copyright © \\d{4}\n// File: \"SWIFTLINT_CURRENT_FILENAME\""]

        // Non triggering tests
        do {
            let violations = try await validate(fileName: "FileNameMatchingSimple.swift", using: configuration1)
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "FileNameMatchingComplex.swift", using: configuration2)
            XCTAssert(violations.isEmpty)
        }

        // Triggering tests
        do {
            let violations = try await validate(fileName: "FileNameCaseMismatch.swift", using: configuration1)
            XCTAssertEqual(violations.count, 1)
        }
        do {
            let violations = try await validate(fileName: "FileNameMismatch.swift", using: configuration1)
            XCTAssertEqual(violations.count, 1)
        }
        do {
            let violations = try await validate(fileName: "FileNameMissing.swift", using: configuration1)
            XCTAssertEqual(violations.count, 1)
        }
    }

    func testFileHeaderWithForbiddenPatternUsingFilenamePlaceholder() async throws {
        let configuration1 = ["forbidden_pattern": "// SWIFTLINT_CURRENT_FILENAME\n.*\\d{4}"]
        let configuration2 = ["forbidden_pattern": "//.*(\\s|\")SWIFTLINT_CURRENT_FILENAME(\\s|\").*"]

        // Non triggering tests
        do {
            let violations = try await validate(fileName: "FileNameCaseMismatch.swift", using: configuration1)
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "FileNameMismatch.swift", using: configuration1)
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "FileNameMissing.swift", using: configuration1)
            XCTAssert(violations.isEmpty)
        }

        do {
            let violations = try await validate(fileName: "FileNameCaseMismatch.swift", using: configuration2)
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "FileNameMismatch.swift", using: configuration2)
            XCTAssert(violations.isEmpty)
        }
        do {
            let violations = try await validate(fileName: "FileNameMissing.swift", using: configuration2)
            XCTAssert(violations.isEmpty)
        }

        // Triggering tests
        do {
            let violations = try await validate(fileName: "FileNameMatchingSimple.swift", using: configuration1)
            XCTAssertEqual(violations.count, 1)
        }
        do {
            let violations = try await validate(fileName: "FileNameMatchingComplex.swift", using: configuration2)
            XCTAssertEqual(violations.count, 1)
        }
    }
}
