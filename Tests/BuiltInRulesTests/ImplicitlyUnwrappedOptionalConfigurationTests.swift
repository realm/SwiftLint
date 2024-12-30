@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

// swiftlint:disable:next type_name
final class ImplicitlyUnwrappedOptionalConfigurationTests: SwiftLintTestCase {
    func testImplicitlyUnwrappedOptionalConfigurationProperlyAppliesConfigurationFromDictionary() throws {
        var configuration = ImplicitlyUnwrappedOptionalConfiguration(
            severityConfiguration: SeverityConfiguration(.warning),
            mode: .allExceptIBOutlets
        )

        try configuration.apply(configuration: ["mode": "all", "severity": "error"])
        XCTAssertEqual(configuration.mode, .all)
        XCTAssertEqual(configuration.severity, .error)

        try configuration.apply(configuration: ["mode": "all_except_iboutlets"])
        XCTAssertEqual(configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(configuration.severity, .error)

        try configuration.apply(configuration: ["severity": "warning"])
        XCTAssertEqual(configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(configuration.severity, .warning)

        try configuration.apply(configuration: ["mode": "all", "severity": "warning"])
        XCTAssertEqual(configuration.mode, .all)
        XCTAssertEqual(configuration.severity, .warning)
    }

    func testImplicitlyUnwrappedOptionalConfigurationThrowsOnBadConfig() {
        let badConfigs: [[String: Any]] = [
            ["mode": "everything"],
            ["mode": false],
            ["mode": 42],
        ]

        for badConfig in badConfigs {
            var configuration = ImplicitlyUnwrappedOptionalConfiguration(
                severityConfiguration: SeverityConfiguration(.warning),
                mode: .allExceptIBOutlets
            )

            checkError(Issue.invalidConfiguration(ruleID: ImplicitlyUnwrappedOptionalRule.identifier)) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }
}
