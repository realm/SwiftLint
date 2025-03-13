@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import TestHelpers
import XCTest

final class RedundantOptionalInitializationRuleTests: SwiftLintTestCase {
    func testDefaultConfiguration() {
        let config = RedundantOptionalInitializationRule.Configuration()
        XCTAssertEqual(config.severityConfiguration.severity, .warning)
        XCTAssertEqual(config.excludedAttributeNames, ["Parameter"])
    }

    func testApplyingCustomConfiguration() throws {
        var config = RedundantOptionalInitializationRule.Configuration()
        try config.apply(
            configuration: [
                "severity": "error",
                "excluded_attribute_names": ["Parameter", "MyCustomAttribute"]
            ] as [String: any Sendable]
        )
        XCTAssertEqual(config.severityConfiguration.severity, .error)
        XCTAssertEqual(config.excludedAttributeNames, ["Parameter", "MyCustomAttribute"])
    }

    func testInvalidKeyInCustomConfiguration() async throws {
        let console = try await Issue.captureConsole {
            var config = RedundantOptionalInitializationRule.Configuration()
            try config.apply(configuration: ["invalidKey": "error"])
        }
        XCTAssertEqual(
            console,
            "warning: Configuration for 'redundant_optional_initialization' rule contains the invalid key(s) 'invalidKey'."
        )
    }

    func testInvalidTypeOfCustomConfiguration() {
        var config = RedundantOptionalInitializationRule.Configuration()
        checkError(Issue.invalidConfiguration(ruleID: RedundantOptionalInitializationRule.identifier)) {
            try config.apply(configuration: "invalidKey")
        }
    }

    func testWithDefaultConfiguration() {
        verifyRule(RedundantOptionalInitializationRule.description)
    }
} 