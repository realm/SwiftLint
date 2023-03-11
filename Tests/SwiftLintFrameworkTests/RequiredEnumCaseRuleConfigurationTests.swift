@testable import SwiftLintFramework
import XCTest

class RequiredEnumCaseRuleConfigurationTests: XCTestCase {
    private typealias RuleConfiguration = RequiredEnumCaseRuleConfiguration
    private typealias RequiredCase = RuleConfiguration.RequiredCase

    private static let protocol1 = "RequiredProtocol"
    private static let protocol2 = "NetworkResults"
    private static let protocol3 = "RequiredProtocolWithSeverity"
    private static let rule1 = RuleConfiguration.RequiredCase(name: "success", severity: .warning)
    private static let rule2 = RuleConfiguration.RequiredCase(name: "error", severity: .warning)
    private static let rule3 = RuleConfiguration.RequiredCase(name: "success", severity: .error)

    private var config: RuleConfiguration = {
        var config = RuleConfiguration()
        config.protocols[protocol1] = [rule1, rule2]
        config.protocols[protocol2] = [rule2]
        return config
    }()

    func testRequiredCaseHashValue() {
        let requiredCase = RequiredCase(name: "success")
        XCTAssertEqual(requiredCase.hashValue, RequiredCase(name: "success").hashValue)
    }

    func testRequiredCaseEquatableReturnsTrue() {
        let lhs = RequiredCase(name: "success")
        let rhs = RequiredCase(name: "success")
        XCTAssertEqual(lhs, rhs)
    }

    func testRequiredCaseEquatableReturnsFalseBecauseOfDifferentName() {
        let lhs = RequiredCase(name: "success")
        let rhs = RequiredCase(name: "error")
        XCTAssertNotEqual(lhs, rhs)
    }

    func testConsoleDescriptionReturnsAllConfiguredProtocols() {
        let expected = "[" +
            "protocol: \"NetworkResults\", " +
            "cases: [" +
                "[name: \"error\", severity: \"warning\"]" +
            "]" +
        "], [" +
            "protocol: \"RequiredProtocol\", " +
            "cases: [" +
                "[name: \"error\", severity: \"warning\"], " +
                "[name: \"success\", severity: \"warning\"]" +
            "]" +
        "]"
        XCTAssertEqual(config.consoleDescription, expected)
    }

    func testConsoleDescriptionReturnsNoConfiguredProtocols() {
        let expected = "No protocols configured.  In config add 'required_enum_case' to 'opt_in_rules' and " +
            "config using :\n\n" +
            "'required_enum_case:\n" +
            "  {Protocol Name}:\n" +
            "    {Case Name}:{warning|error}\n" +
            "    {Case Name}:{warning|error}\n"

        config.protocols.removeAll()
        XCTAssertEqual(config.consoleDescription, expected)
    }

    private func validateRulesExistForProtocol1() {
        XCTAssertTrue(self.config.protocols[Self.protocol1]?.contains(Self.rule1) ?? false)
        XCTAssertTrue(self.config.protocols[Self.protocol1]?.contains(Self.rule2) ?? false)
    }

    func testRegisterProtocolCasesRegistersCasesWithSpecifiedSeverity() {
        config.register(protocol: Self.protocol3, cases: ["success": "error", "error": "warning"])
        validateRulesExistForProtocol3()
    }

    private func validateRulesExistForProtocol3() {
        XCTAssertTrue(self.config.protocols[Self.protocol3]?.contains(Self.rule3) ?? false)
        XCTAssertTrue(self.config.protocols[Self.protocol3]?.contains(Self.rule2) ?? false)
    }

    func testRegisterProtocols() {
        config.register(protocols: [Self.protocol1: ["success": "warning", "error": "warning"]])
        validateRulesExistForProtocol1()
    }

    func testApplyThrowsErrorBecausePassedConfigurationCantBeCast() {
        var errorThrown = false

        do {
            try config.apply(configuration: "Howdy")
        } catch {
            errorThrown = true
        }

        XCTAssertTrue(errorThrown)
    }

    func testApplyRegistersProtocols() {
        try? config.apply(configuration: [Self.protocol1: ["success": "warning", "error": "warning"]])
        validateRulesExistForProtocol1()
    }

    func testEqualsReturnsTrue() {
        var lhs = RuleConfiguration()
        try? lhs.apply(configuration: [Self.protocol1: ["success", "error"]])

        var rhs = RuleConfiguration()
        try? rhs.apply(configuration: [Self.protocol1: ["success", "error"]])

        XCTAssertEqual(lhs, rhs)
    }

    func testEqualsReturnsFalseBecauseProtocolsArentEqual() {
        var lhs = RuleConfiguration()
        try? lhs.apply(configuration: [Self.protocol1: ["success": "error"]])

        var rhs = RuleConfiguration()
        try? rhs.apply(configuration: [Self.protocol2: ["success": "error", "error": "warning"]])

        XCTAssertNotEqual(lhs, rhs)
    }

    func testEqualsReturnsFalseBecauseSeverityIsntEqual() {
        var lhs = RuleConfiguration()
        try? lhs.apply(configuration: [Self.protocol1: ["success": "error", "error": "error"]])

        var rhs = RuleConfiguration()
        try? rhs.apply(configuration: [Self.protocol1: ["success": "warning", "error": "error"]])

        XCTAssertNotEqual(lhs, rhs)
    }
}
