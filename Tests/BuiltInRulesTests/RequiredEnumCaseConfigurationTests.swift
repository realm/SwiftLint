import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
final class RequiredEnumCaseConfigurationTests {
    private typealias RuleConfiguration = RequiredEnumCaseConfiguration
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

    @Test
    func requiredCaseHashValue() {
        let requiredCase = RequiredCase(name: "success")
        #expect(requiredCase.hashValue == RequiredCase(name: "success").hashValue)
    }

    @Test
    func requiredCaseEquatableReturnsTrue() {
        let lhs = RequiredCase(name: "success")
        let rhs = RequiredCase(name: "success")
        #expect(lhs == rhs)
    }

    @Test
    func requiredCaseEquatableReturnsFalseBecauseOfDifferentName() {
        let lhs = RequiredCase(name: "success")
        let rhs = RequiredCase(name: "error")
        #expect(lhs != rhs)
    }

    @Test
    func consoleDescriptionReturnsAllConfiguredProtocols() {
        let expected = "NetworkResults: error: warning; RequiredProtocol: error: warning, success: warning"
        #expect(config.parameterDescription?.oneLiner() == expected)
    }

    @Test
    func consoleDescriptionReturnsNoConfiguredProtocols() {
        let expected = "{Protocol Name}: {Case Name 1}: {warning|error}, {Case Name 2}: {warning|error}"

        config.protocols.removeAll()
        #expect(config.parameterDescription?.oneLiner() == expected)
    }

    private func validateRulesExistForProtocol1() {
        #expect(self.config.protocols[Self.protocol1]?.contains(Self.rule1) ?? false)
        #expect(self.config.protocols[Self.protocol1]?.contains(Self.rule2) ?? false)
    }

    @Test
    func registerProtocolCasesRegistersCasesWithSpecifiedSeverity() {
        config.register(protocol: Self.protocol3, cases: ["success": "error", "error": "warning"])
        validateRulesExistForProtocol3()
    }

    private func validateRulesExistForProtocol3() {
        #expect(self.config.protocols[Self.protocol3]?.contains(Self.rule3) ?? false)
        #expect(self.config.protocols[Self.protocol3]?.contains(Self.rule2) ?? false)
    }

    @Test
    func registerProtocols() {
        config.register(protocols: [Self.protocol1: ["success": "warning", "error": "warning"]])
        validateRulesExistForProtocol1()
    }

    @Test
    func applyThrowsErrorBecausePassedConfigurationCantBeCast() {
        var errorThrown = false

        do {
            try config.apply(configuration: "Howdy")
        } catch {
            errorThrown = true
        }

        #expect(errorThrown)
    }

    @Test
    func applyRegistersProtocols() {
        try? config.apply(configuration: [Self.protocol1: ["success": "warning", "error": "warning"]])
        validateRulesExistForProtocol1()
    }

    @Test
    func equalsReturnsTrue() {
        var lhs = RuleConfiguration()
        try? lhs.apply(configuration: [Self.protocol1: ["success", "error"]])

        var rhs = RuleConfiguration()
        try? rhs.apply(configuration: [Self.protocol1: ["success", "error"]])

        #expect(lhs == rhs)
    }

    @Test
    func equalsReturnsFalseBecauseProtocolsArentEqual() {
        var lhs = RuleConfiguration()
        try? lhs.apply(configuration: [Self.protocol1: ["success": "error"]])

        var rhs = RuleConfiguration()
        try? rhs.apply(configuration: [Self.protocol2: ["success": "error", "error": "warning"]])

        #expect(lhs != rhs)
    }

    @Test
    func equalsReturnsFalseBecauseSeverityIsntEqual() {
        var lhs = RuleConfiguration()
        try? lhs.apply(configuration: [Self.protocol1: ["success": "error", "error": "error"]])

        var rhs = RuleConfiguration()
        try? rhs.apply(configuration: [Self.protocol1: ["success": "warning", "error": "error"]])

        #expect(lhs != rhs)
    }
}
