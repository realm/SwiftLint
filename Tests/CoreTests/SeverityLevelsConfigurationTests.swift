@testable import SwiftLintCore
import TestHelpers
import XCTest

struct MockSeverityLevelsRule: Rule {
    static let identifier = "test_severity_levels"
    static let description = RuleDescription(
        identifier: identifier,
        name: "Test Severity Levels",
        description: "A test rule for SeverityLevelsConfiguration",
        kind: .style
    )

    var configuration = SeverityLevelsConfiguration<Self>(warning: 12, error: nil)

    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        []
    }
}

final class SeverityLevelsConfigurationTests: SwiftLintTestCase {
    func testInitializationWithWarningOnly() {
        let config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 10)
        XCTAssertEqual(config.warning, 10)
        XCTAssertNil(config.error)

        let params = config.params
        XCTAssertEqual(params.count, 1)
        XCTAssertEqual(params[0].severity, .warning)
        XCTAssertEqual(params[0].value, 10)
    }

    func testInitializationWithWarningAndError() {
        let config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 10, error: 20)
        XCTAssertEqual(config.warning, 10)
        XCTAssertEqual(config.error, 20)

        let params = config.params
        XCTAssertEqual(params.count, 2)
        XCTAssertEqual(params[0].severity, .error)
        XCTAssertEqual(params[0].value, 20)
        XCTAssertEqual(params[1].severity, .warning)
        XCTAssertEqual(params[1].value, 10)
    }

    func testApplyConfigurationWithSingleElementArray() throws {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

        try config.apply(configuration: [15])

        XCTAssertEqual(config.warning, 15)
        XCTAssertNil(config.error)
    }

    func testApplyConfigurationWithTwoElementArray() throws {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

        try config.apply(configuration: [10, 25])

        XCTAssertEqual(config.warning, 10)
        XCTAssertEqual(config.error, 25)
    }

    func testApplyConfigurationWithMultipleElementArray() throws {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

        try config.apply(configuration: [10, 25, 50])

        XCTAssertEqual(config.warning, 10)
        XCTAssertEqual(config.error, 25) // Only first two elements are used
    }

    func testApplyConfigurationWithEmptyArray() {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

        checkError(Issue.nothingApplied(ruleID: MockSeverityLevelsRule.identifier)) {
            try config.apply(configuration: [] as [Int])
        }
    }

    func testApplyConfigurationWithInvalidArrayType() {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

        checkError(Issue.nothingApplied(ruleID: MockSeverityLevelsRule.identifier)) {
            try config.apply(configuration: ["invalid"])
        }
    }

    func testApplyConfigurationWithWarningOnlyDictionary() throws {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

        try config.apply(configuration: ["warning": 15])

        XCTAssertEqual(config.warning, 15)
        XCTAssertNil(config.error)
    }

    func testApplyConfigurationWithWarningAndErrorDictionary() throws {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

        try config.apply(configuration: ["warning": 10, "error": 25])

        XCTAssertEqual(config.warning, 10)
        XCTAssertEqual(config.error, 25)
    }

    func testApplyConfigurationWithErrorOnlyDictionary() throws {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

        try config.apply(configuration: ["error": 25])

        XCTAssertEqual(config.warning, 12) // Should remain unchanged
        XCTAssertEqual(config.error, 25)
    }

    func testApplyConfigurationWithNilErrorDictionary() throws {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 10, error: 20)

        try config.apply(configuration: ["error": nil as Int?])

        XCTAssertEqual(config.warning, 10)
        XCTAssertNil(config.error)
    }

    func testApplyConfigurationWithWarningSetToNilError() throws {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 10, error: 20)

        try config.apply(configuration: ["warning": 15])

        XCTAssertEqual(config.warning, 15)
        XCTAssertNil(config.error) // Should be set to nil when warning is specified without error
    }

    func testApplyConfigurationWithInvalidWarningType() {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

        checkError(Issue.invalidConfiguration(ruleID: MockSeverityLevelsRule.identifier)) {
            try config.apply(configuration: ["warning": "invalid"])
        }
    }

    func testApplyConfigurationWithInvalidErrorType() {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

        checkError(Issue.invalidConfiguration(ruleID: MockSeverityLevelsRule.identifier)) {
            try config.apply(configuration: ["error": "invalid"])
        }
    }

    func testApplyConfigurationWithInvalidConfigurationType() {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

        checkError(Issue.nothingApplied(ruleID: MockSeverityLevelsRule.identifier)) {
            try config.apply(configuration: "invalid")
        }
    }

    func testApplyConfigurationWithEmptyDictionary() throws {
        var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: 15)

        try config.apply(configuration: [:] as [String: Any])

        XCTAssertEqual(config.warning, 12)
        XCTAssertEqual(config.error, 15) // Should remain unchanged when nothing is applied
    }
}
