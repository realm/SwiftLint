@testable import SwiftLintBuiltInRules
import XCTest

class ExplicitTypeInterfaceConfigurationTests: SwiftLintTestCase {
    func testDefaultConfiguration() {
        let config = ExplicitTypeInterfaceConfiguration()
        XCTAssertEqual(config.severityConfiguration.severity, .warning)
        XCTAssertEqual(config.allowedKinds, Set([.instance, .class, .static, .local]))
    }

    func testApplyingCustomConfiguration() throws {
        var config = ExplicitTypeInterfaceConfiguration()
        try config.apply(configuration: ["severity": "error",
                                         "excluded": ["local"],
                                         "allow_redundancy": true] as [String: Any])
        XCTAssertEqual(config.severityConfiguration.severity, .error)
        XCTAssertEqual(config.allowedKinds, Set([.instance, .class, .static]))
        XCTAssertTrue(config.allowRedundancy)
    }

    func testInvalidKeyInCustomConfiguration() {
        var config = ExplicitTypeInterfaceConfiguration()
        checkError(Issue.unknownConfiguration(ruleID: ExplicitTypeInterfaceRule.description.identifier)) {
            try config.apply(configuration: ["invalidKey": "error"])
        }
    }

    func testInvalidTypeOfCustomConfiguration() {
        var config = ExplicitTypeInterfaceConfiguration()
        checkError(Issue.unknownConfiguration(ruleID: ExplicitTypeInterfaceRule.description.identifier)) {
            try config.apply(configuration: "invalidKey")
        }
    }

    func testInvalidTypeOfValueInCustomConfiguration() {
        var config = ExplicitTypeInterfaceConfiguration()
        checkError(Issue.unknownConfiguration(ruleID: ExplicitTypeInterfaceRule.description.identifier)) {
            try config.apply(configuration: ["severity": 1])
        }
    }

    func testConsoleDescription() throws {
        var config = ExplicitTypeInterfaceConfiguration()
        try config.apply(configuration: ["excluded": ["class", "instance"]])
        XCTAssertEqual(
            config.consoleDescription,
            "severity: warning, excluded: [\"class\", \"instance\"], allow_redundancy: false"
        )
    }
}
