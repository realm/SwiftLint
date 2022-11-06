@testable import SwiftLintBuiltInRules
import XCTest

class RequiredEnumCaseRuleConfigurationTests: SwiftLintTestCase {
    private typealias RuleConfiguration = RequiredEnumCaseRuleConfiguration
    private typealias RequiredCase = RuleConfiguration.RequiredCase

    private let protocol1 = "RequiredProtocol"
    private let protocol2 = "NetworkResults"
    private let protocol3 = "RequiredProtocolWithSeverity"
    private let rule1 = RuleConfiguration.RequiredCase(name: "success", severity: .warning)
    private let rule2 = RuleConfiguration.RequiredCase(name: "error", severity: .warning)
    private let rule3 = RuleConfiguration.RequiredCase(name: "success", severity: .error)

    private var config: RuleConfiguration!

    override func setUp() {
        super.setUp()
        config = RuleConfiguration()
        config.protocols[protocol1] = [rule1, rule2]
        config.protocols[protocol2] = [rule2]
    }

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
        XCTAssertTrue(self.config.protocols[protocol1]?.contains(self.rule1) ?? false)
        XCTAssertTrue(self.config.protocols[protocol1]?.contains(self.rule2) ?? false)
    }

    func testRegisterProtocolCasesRegistersCasesWithSpecifiedSeverity() {
        config.register(protocol: protocol3, cases: ["success": "error", "error": "warning"])
        validateRulesExistForProtocol3()
    }

    private func validateRulesExistForProtocol3() {
        XCTAssertTrue(self.config.protocols[protocol3]?.contains(self.rule3) ?? false)
        XCTAssertTrue(self.config.protocols[protocol3]?.contains(self.rule2) ?? false)
    }

    func testRegisterProtocols() {
        config.register(protocols: [protocol1: ["success": "warning", "error": "warning"]])
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
        try? config.apply(configuration: [protocol1: ["success": "warning", "error": "warning"]])
        validateRulesExistForProtocol1()
    }

    func testEqualsReturnsTrue() {
        var lhs = RuleConfiguration()
        try? lhs.apply(configuration: [protocol1: ["success", "error"]])

        var rhs = RuleConfiguration()
        try? rhs.apply(configuration: [protocol1: ["success", "error"]])

        XCTAssertEqual(lhs, rhs)
    }

    func testEqualsReturnsFalseBecauseProtocolsArentEqual() {
        var lhs = RuleConfiguration()
        try? lhs.apply(configuration: [protocol1: ["success": "error"]])

        var rhs = RuleConfiguration()
        try? rhs.apply(configuration: [protocol2: ["success": "error", "error": "warning"]])

        XCTAssertNotEqual(lhs, rhs)
    }

    func testEqualsReturnsFalseBecauseSeverityIsntEqual() {
        var lhs = RuleConfiguration()
        try? lhs.apply(configuration: [protocol1: ["success": "error", "error": "error"]])

        var rhs = RuleConfiguration()
        try? rhs.apply(configuration: [protocol1: ["success": "warning", "error": "error"]])

        XCTAssertNotEqual(lhs, rhs)
    }
}
