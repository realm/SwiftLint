@testable import SwiftLintCore
import TestHelpers
import XCTest

final class RegexConfigurationTests: SwiftLintTestCase {
    func testShouldValidateIsTrueByDefault() {
        let config = RegexConfiguration<MockRule>(identifier: "example")
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url()))
    }

    func testShouldValidateWithSingleExcluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "excluded": "ExcludedFolder/.*\\.swift",
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "ExcludedFolder/file.swift".url()))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url()))
    }

    func testShouldValidateWithArrayExcluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "excluded": [
                "ExcludedFolder/.*\\.swift",
                "MyFramework/ExcludedFolder/.*\\.swift",
            ] as Any,
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "ExcludedFolder/file.swift".url()))
        XCTAssertFalse(config.shouldValidate(filePath: "MyFramework/ExcludedFolder/file.swift".url()))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url()))
    }

    func testShouldValidateWithSingleIncluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": "App/.*\\.swift",
        ])

        XCTAssertFalse(config.shouldValidate(filePath: "ExcludedFolder/file.swift".url()))
        XCTAssertFalse(config.shouldValidate(filePath: "MyFramework/ExcludedFolder/file.swift".url()))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url()))
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

        XCTAssertFalse(config.shouldValidate(filePath: "ExcludedFolder/file.swift".url()))
        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url()))
        XCTAssertTrue(config.shouldValidate(filePath: "MyFramework/file.swift".url()))
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
                "ExcludedFolder/.*\\.swift",
                "App/Fixtures/.*\\.swift",
            ] as Any,
        ])

        XCTAssertTrue(config.shouldValidate(filePath: "App/file.swift".url()))
        XCTAssertTrue(config.shouldValidate(filePath: "MyFramework/file.swift".url()))

        XCTAssertFalse(config.shouldValidate(filePath: "App/Fixtures/file.swift".url()))
        XCTAssertFalse(config.shouldValidate(filePath: "ExcludedFolder/file.swift".url()))
        XCTAssertFalse(config.shouldValidate(filePath: "MyFramework/ExcludedFolder/file.swift".url()))
    }
}
