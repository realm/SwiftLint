@testable import SwiftLintCore
import XCTest

class RegexConfigurationTests: SwiftLintTestCase {
    func testShouldValidateIsTrueByDefault() {
        let config = RegexConfiguration<RuleMock>(identifier: "example")
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift"))
    }

    func testShouldValidateWithSingleExluded() throws {
        var config = RegexConfiguration<RuleMock>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "excluded": "Tests/.*\\.swift"
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift"))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift"))
    }

    func testShouldValidateWithArrayExluded() throws {
        var config = RegexConfiguration<RuleMock>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "excluded": [
                "^Tests/.*\\.swift",
                "^MyFramework/Tests/.*\\.swift"
            ] as Any
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift"))
        XCTAssertFalse(config.shouldValidate(filePath: "MyFramework/Tests/file.swift"))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift"))
    }

    func testShouldValidateWithSingleIncluded() throws {
        var config = RegexConfiguration<RuleMock>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": "App/.*\\.swift"
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift"))
        XCTAssertFalse(config.shouldValidate(filePath: "MyFramework/Tests/file.swift"))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift"))
    }

    func testShouldValidateWithArrayIncluded() throws {
        var config = RegexConfiguration<RuleMock>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": [
                "App/.*\\.swift",
                "MyFramework/.*\\.swift"
            ] as Any
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift"))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift"))
        XCTAssertTrue(config.shouldValidate(filePath: "MyFramework/file.swift"))
    }

    func testShouldValidateWithIncludedAndExcluded() throws {
        var config = RegexConfiguration<RuleMock>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": [
                "App/.*\\.swift",
                "MyFramework/.*\\.swift"
            ] as Any,
            "excluded": [
                "Tests/.*\\.swift",
                "App/Fixtures/.*\\.swift"
            ] as Any
        ])

        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift"))
        XCTAssertTrue(config.shouldValidate(filePath: "MyFramework/file.swift"))

        XCTAssertFalse(config.shouldValidate(filePath: "App/Fixtures/file.swift"))
        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift"))
        XCTAssertFalse(config.shouldValidate(filePath: "MyFramework/Tests/file.swift"))
    }
}
