import SourceKittenFramework
@testable import SwiftLintFramework
import SwiftLintTestHelpers
import XCTest

private let fixturesDirectory = #file.bridge()
    .deletingLastPathComponent.bridge()
    .appendingPathComponent("Resources/FileHeaderRuleFixtures")

class FileHeaderRuleTests: XCTestCase {
    private func validate(fileName: String, using configuration: Any) throws -> [StyleViolation] {
        let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
        let rule = try FileHeaderRule(configuration: configuration)
        return rule.validate(file: file)
    }

    func testFileHeaderWithDefaultConfiguration() {
        verifyRule(FileHeaderRule.description, skipCommentTests: true)
    }

    func testFileHeaderWithRequiredString() {
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

        verifyRule(description, ruleConfiguration: ["required_string": "**Header"],
                   stringDoesntViolate: false, skipCommentTests: true,
                   testMultiByteOffsets: false, testShebang: false)
    }

    func testFileHeaderWithRequiredPattern() {
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

        verifyRule(description, ruleConfiguration: ["required_pattern": "\\d{4} Realm"],
                   stringDoesntViolate: false, skipCommentTests: true,
                   testMultiByteOffsets: false)
    }

    func testFileHeaderWithRequiredStringAndURLComment() {
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
        verifyRule(description, ruleConfiguration: config,
                   stringDoesntViolate: false, skipCommentTests: true,
                   testMultiByteOffsets: false)
    }

    func testFileHeaderWithForbiddenString() {
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

        verifyRule(description, ruleConfiguration: ["forbidden_string": "**All rights reserved."],
                   skipCommentTests: true)
    }

    func testFileHeaderWithForbiddenPattern() {
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

        verifyRule(description, ruleConfiguration: ["forbidden_pattern": "\\s\\w+\\.swift"],
                   skipCommentTests: true)
    }

    func testFileHeaderWithForbiddenPatternAndDocComment() {
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

        verifyRule(description, ruleConfiguration: ["forbidden_pattern": "[tT]ests"],
                   skipCommentTests: true, testMultiByteOffsets: false)
    }

    func testFileHeaderWithRequiredStringUsingFilenamePlaceholder() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        let configuration = ["required_string": "// SWIFTLINT_CURRENT_FILENAME"]

        // Non triggering tests
        XCTAssert(try validate(fileName: "FileNameMatchingSimple.swift", using: configuration).isEmpty)

        // Triggering tests
        XCTAssertEqual(try validate(fileName: "FileNameCaseMismatch.swift", using: configuration).count, 1)
        XCTAssertEqual(try validate(fileName: "FileNameMismatch.swift", using: configuration).count, 1)
        XCTAssertEqual(try validate(fileName: "FileNameMissing.swift", using: configuration).count, 1)
    }

    func testFileHeaderWithForbiddenStringUsingFilenamePlaceholder() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        let configuration = ["forbidden_string": "// SWIFTLINT_CURRENT_FILENAME"]

        // Non triggering tests
        XCTAssert(try validate(fileName: "FileNameCaseMismatch.swift", using: configuration).isEmpty)
        XCTAssert(try validate(fileName: "FileNameMismatch.swift", using: configuration).isEmpty)
        XCTAssert(try validate(fileName: "FileNameMissing.swift", using: configuration).isEmpty)

        // Triggering tests
        XCTAssertEqual(try validate(fileName: "FileNameMatchingSimple.swift", using: configuration).count, 1)
    }

    func testFileHeaderWithRequiredPatternUsingFilenamePlaceholder() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        let configuration1 = ["required_pattern": "// SWIFTLINT_CURRENT_FILENAME\n.*\\d{4}"]
        let configuration2 = ["required_pattern":
            "// Copyright © \\d{4}\n// File: \"SWIFTLINT_CURRENT_FILENAME\""]

        // Non triggering tests
        XCTAssert(try validate(fileName: "FileNameMatchingSimple.swift", using: configuration1).isEmpty)
        XCTAssert(try validate(fileName: "FileNameMatchingComplex.swift", using: configuration2).isEmpty)

        // Triggering tests
        XCTAssertEqual(try validate(fileName: "FileNameCaseMismatch.swift", using: configuration1).count, 1)
        XCTAssertEqual(try validate(fileName: "FileNameMismatch.swift", using: configuration1).count, 1)
        XCTAssertEqual(try validate(fileName: "FileNameMissing.swift", using: configuration1).count, 1)
    }

    func testFileHeaderWithForbiddenPatternUsingFilenamePlaceholder() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        let configuration1 = ["forbidden_pattern": "// SWIFTLINT_CURRENT_FILENAME\n.*\\d{4}"]
        let configuration2 = ["forbidden_pattern": "//.*(\\s|\")SWIFTLINT_CURRENT_FILENAME(\\s|\").*"]

        // Non triggering tests
        XCTAssert(try validate(fileName: "FileNameCaseMismatch.swift", using: configuration1).isEmpty)
        XCTAssert(try validate(fileName: "FileNameMismatch.swift", using: configuration1).isEmpty)
        XCTAssert(try validate(fileName: "FileNameMissing.swift", using: configuration1).isEmpty)

        XCTAssert(try validate(fileName: "FileNameCaseMismatch.swift", using: configuration2).isEmpty)
        XCTAssert(try validate(fileName: "FileNameMismatch.swift", using: configuration2).isEmpty)
        XCTAssert(try validate(fileName: "FileNameMissing.swift", using: configuration2).isEmpty)

        // Triggering tests
        XCTAssertEqual(try validate(fileName: "FileNameMatchingSimple.swift", using: configuration1).count, 1)
        XCTAssertEqual(try validate(fileName: "FileNameMatchingComplex.swift", using: configuration2).count, 1)
    }
}
