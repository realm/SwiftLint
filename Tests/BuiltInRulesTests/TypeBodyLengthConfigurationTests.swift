@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class TypeBodyLengthConfigurationTests: SwiftLintTestCase {
    func testDefaultConfiguration() {
        let config = TypeBodyLengthConfiguration()
        XCTAssertEqual(config.severityConfiguration.warning, 250)
        XCTAssertEqual(config.severityConfiguration.error, 350)
        XCTAssertEqual(config.excludedTypes, [.extension, .protocol])
    }

    func testApplyingCustomConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
            configuration: [
                "warning": 150,
                "error": 200,
                "excluded_types": ["struct", "class"],
            ] as [String: any Sendable]
        )
        XCTAssertEqual(config.severityConfiguration.warning, 150)
        XCTAssertEqual(config.severityConfiguration.error, 200)
        XCTAssertEqual(config.excludedTypes, Set([.struct, .class]))
    }

    func testApplyingOnlyExcludedTypesConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
                configuration: [
                    "excluded_types": ["actor", "enum"]
                ] as [String: any Sendable]
            )

        // Severity should remain default
        XCTAssertEqual(config.severityConfiguration.warning, 250)
        XCTAssertEqual(config.severityConfiguration.error, 350)

        // Excluded types should be updated
        XCTAssertEqual(config.excludedTypes, Set([.actor, .enum]))
    }

    func testApplyingAllTypesAsExcludedConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
            configuration: [
                "excluded_types": ["struct", "class", "actor", "enum", "extension", "protocol"]
            ] as [String: any Sendable]
        )
        XCTAssertEqual(config.excludedTypes, Set(TypeBodyLengthCheckType.allCases))
    }

    func testApplyingEmptyExcludedTypesConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
            configuration: [
                "excluded_types": [] as [String]
            ] as [String: any Sendable]
        )
        XCTAssertTrue(config.excludedTypes.isEmpty)
    }

    func testApplyingSingleExcludedTypeConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
            configuration: [
                "excluded_types": ["extension"]
            ] as [String: any Sendable]
        )
        XCTAssertEqual(config.excludedTypes, Set([.extension]))
    }

    func testInvalidExcludedTypeConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: TypeBodyLengthRule.identifier)) {
            try config.apply(
                configuration: [
                    "excluded_types": ["invalid_type"]
                ] as [String: any Sendable]
            )
        }
        XCTAssertEqual(config.excludedTypes, Set([.extension, .protocol]))
    }

    func testTypeEnumComparability() {
        XCTAssertEqual(
            TypeBodyLengthCheckType.allCases.sorted(),
            [.actor, .class, .enum, .extension, .protocol, .struct]
        )
    }
}
