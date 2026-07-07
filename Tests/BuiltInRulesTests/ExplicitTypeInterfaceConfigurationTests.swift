import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

@Suite(.rulesRegistered)
struct ExplicitTypeInterfaceConfigurationTests {
    @Test
    func defaultConfiguration() {
        let config = ExplicitTypeInterfaceConfiguration()
        #expect(config.severityConfiguration.severity == .warning)
        #expect(config.allowedKinds == Set([.instance, .class, .static, .local]))
    }

    @Test
    func applyingCustomConfiguration() throws {
        var config = ExplicitTypeInterfaceConfiguration()
        try config.apply(
            configuration: [
                "severity": "error",
                "excluded": ["local"],
                "allow_redundancy": true,
            ] as [String: any Sendable]
        )
        #expect(config.severityConfiguration.severity == .error)
        #expect(config.allowedKinds == Set([.instance, .class, .static]))
        #expect(config.allowRedundancy)
    }

    @Test
    func invalidKeyInCustomConfiguration() async throws {
        let console = try await Issue.captureConsole {
            var config = ExplicitTypeInterfaceConfiguration()
            try config.apply(configuration: ["invalidKey": "error"])
        }
        #expect(
            console
                == "warning: Configuration for 'explicit_type_interface' rule contains the invalid key(s) 'invalidKey'."
        )
    }

    @Test
    func invalidTypeOfCustomConfiguration() {
        var config = ExplicitTypeInterfaceConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: ExplicitTypeInterfaceRule.identifier)) {
            try config.apply(configuration: "invalidKey")
        }
    }

    @Test
    func invalidTypeOfValueInCustomConfiguration() {
        var config = ExplicitTypeInterfaceConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: ExplicitTypeInterfaceRule.identifier)) {
            try config.apply(configuration: ["severity": "foo"])
        }
    }

    @Test
    func consoleDescription() throws {
        var config = ExplicitTypeInterfaceConfiguration()
        try config.apply(configuration: ["excluded": ["class", "instance"]])
        #expect(
            RuleConfigurationDescription.from(configuration: config).oneLiner()
                == "severity: warning; excluded: [class, instance]; allow_redundancy: false"
        )
    }
}
