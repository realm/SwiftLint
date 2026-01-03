@testable import SwiftLintCore
import TestHelpers
import XCTest

final class RegexConfigurationTests: SwiftLintTestCase {
    func testShouldValidateIsTrueByDefault() {
        let config = RegexConfiguration<MockRule>(identifier: "example")
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url))
    }

    func testShouldValidateWithSingleExluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "excluded": "Tests/.*\\.swift",
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift".url))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url))
    }

    func testShouldValidateWithArrayExluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "excluded": [
                "^Tests/.*\\.swift",
                "^MyFramework/Tests/.*\\.swift",
            ] as Any,
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift".url))
        XCTAssertFalse(config.shouldValidate(filePath: "MyFramework/Tests/file.swift".url))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url))
    }

    func testShouldValidateWithSingleIncluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": "App/.*\\.swift",
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift".url))
        XCTAssertFalse(config.shouldValidate(filePath: "MyFramework/Tests/file.swift".url))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url))
    }

    func testShouldValidateWithArrayIncluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": [
                "App/.*\\.swift",
                "MyFramework/.*\\.swift",
            ] as Any,
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift".url))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url))
        XCTAssertTrue(config.shouldValidate(filePath: "MyFramework/file.swift".url))
    }

    func testShouldValidateWithIncludedAndExcluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": [
                "App/.*\\.swift",
                "MyFramework/.*\\.swift",
            ] as Any,
            "excluded": [
                "Tests/.*\\.swift",
                "App/Fixtures/.*\\.swift",
            ] as Any,
        ])

        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url))
        XCTAssertTrue(config.shouldValidate(filePath: "MyFramework/file.swift".url))

        XCTAssertFalse(config.shouldValidate(filePath: "App/Fixtures/file.swift".url))
        XCTAssertFalse(config.shouldValidate(filePath: "Tests/file.swift".url))
        XCTAssertFalse(config.shouldValidate(filePath: "MyFramework/Tests/file.swift".url))
    }
}
