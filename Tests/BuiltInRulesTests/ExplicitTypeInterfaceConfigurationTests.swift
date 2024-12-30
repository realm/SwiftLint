@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import TestHelpers
import XCTest

final class ExplicitTypeInterfaceConfigurationTests: SwiftLintTestCase {
    func testDefaultConfiguration() {
        let config = ExplicitTypeInterfaceConfiguration()
        XCTAssertEqual(config.severityConfiguration.severity, .warning)
        XCTAssertEqual(config.allowedKinds, Set([.instance, .class, .static, .local]))
    }

    func testApplyingCustomConfiguration() throws {
        var config = ExplicitTypeInterfaceConfiguration()
        try config.apply(
            configuration: [
                "severity": "error",
                "excluded": ["local"],
                "allow_redundancy": true,
            ] as [String: any Sendable]
        )
        XCTAssertEqual(config.severityConfiguration.severity, .error)
        XCTAssertEqual(config.allowedKinds, Set([.instance, .class, .static]))
        XCTAssertTrue(config.allowRedundancy)
    }

    @MainActor
    func testInvalidKeyInCustomConfiguration() async throws {
        var config = ExplicitTypeInterfaceConfiguration()
        try await AsyncAssertEqual(
            try await Issue.captureConsole { try config.apply(configuration: ["invalidKey": "error"]) },
            "warning: Configuration for 'explicit_type_interface' rule contains the invalid key(s) 'invalidKey'."
        )
    }

    func testInvalidTypeOfCustomConfiguration() {
        var config = ExplicitTypeInterfaceConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: ExplicitTypeInterfaceRule.identifier)) {
            try config.apply(configuration: "invalidKey")
        }
    }

    func testInvalidTypeOfValueInCustomConfiguration() {
        var config = ExplicitTypeInterfaceConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: ExplicitTypeInterfaceRule.identifier)) {
            try config.apply(configuration: ["severity": "foo"])
        }
    }

    func testConsoleDescription() throws {
        var config = ExplicitTypeInterfaceConfiguration()
        try config.apply(configuration: ["excluded": ["class", "instance"]])
        XCTAssertEqual(
            RuleConfigurationDescription.from(configuration: config).oneLiner(),
            "severity: warning; excluded: [class, instance]; allow_redundancy: false"
        )
    }
}
