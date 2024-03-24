@testable import SwiftLintBuiltInRules
import XCTest

// swiftlint:disable:next type_name
class ImplicitlyUnwrappedOptionalConfigurationTests: SwiftLintTestCase {
    func testImplicitlyUnwrappedOptionalConfigurationProperlyAppliesConfigurationFromDictionary() throws {
        var configuration = ImplicitlyUnwrappedOptionalConfiguration(
            severity: .warning,
            mode: .allExceptIBOutlets
        )

        try configuration.apply(configuration: ["mode": "all", "severity": "error"])
        XCTAssertEqual(configuration.mode, .all)
        XCTAssertEqual(configuration.violationSeverity, .error)

        try configuration.apply(configuration: ["mode": "all_except_iboutlets"])
        XCTAssertEqual(configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(configuration.violationSeverity, .error)

        try configuration.apply(configuration: ["severity": "warning"])
        XCTAssertEqual(configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(configuration.violationSeverity, .warning)

        try configuration.apply(configuration: ["mode": "all", "severity": "warning"])
        XCTAssertEqual(configuration.mode, .all)
        XCTAssertEqual(configuration.violationSeverity, .warning)
    }

    func testImplicitlyUnwrappedOptionalConfigurationThrowsOnBadConfig() {
        let badConfigs: [[String: Any]] = [
            ["mode": "everything"],
            ["mode": false],
            ["mode": 42]
        ]

        for badConfig in badConfigs {
            var configuration = ImplicitlyUnwrappedOptionalConfiguration(
                severity: .warning,
                mode: .allExceptIBOutlets
            )

            checkError(Issue.invalidConfiguration(ruleID: ImplicitlyUnwrappedOptionalRule.description.identifier)) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }
}
