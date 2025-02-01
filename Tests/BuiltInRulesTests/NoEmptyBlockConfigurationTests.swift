import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

@Suite(.rulesRegistered)
struct NoEmptyBlockConfigurationTests {
    @Test
    func defaultConfiguration() {
        let config = NoEmptyBlockConfiguration()
        #expect(config.severityConfiguration.severity == .warning)
        #expect(config.enabledBlockTypes == NoEmptyBlockConfiguration.CodeBlockType.all)
    }

    @Test
    func applyingCustomConfiguration() throws {
        var config = NoEmptyBlockConfiguration()
        try config.apply(
            configuration: [
                "severity": "error",
                "disabled_block_types": ["function_bodies"],
            ] as [String: any Sendable]
        )
        #expect(config.severityConfiguration.severity == .error)
        #expect(config.enabledBlockTypes == Set([.initializerBodies, .statementBlocks, .closureBlocks]))
    }

    @Test
    func invalidKeyInCustomConfiguration() async throws {
        let console = try await Issue.captureConsole {
            var config = NoEmptyBlockConfiguration()
            try config.apply(configuration: ["invalidKey": "error"])
        }
        #expect(
            console == "warning: Configuration for 'no_empty_block' rule contains the invalid key(s) 'invalidKey'."
        )
    }

    @Test
    func invalidTypeOfCustomConfiguration() {
        var config = NoEmptyBlockConfiguration()
        #expect(throws: Issue.invalidConfiguration(ruleID: NoEmptyBlockRule.identifier)) {
            try config.apply(configuration: "invalidKey")
        }
    }

    @Test
    func invalidTypeOfValueInCustomConfiguration() {
        var config = NoEmptyBlockConfiguration()
        #expect(throws: Issue.invalidConfiguration(ruleID: NoEmptyBlockRule.identifier)) {
            try config.apply(configuration: ["severity": "foo"])
        }
    }

    @Test
    func consoleDescription() throws {
        var config = NoEmptyBlockConfiguration()
        try config.apply(configuration: ["disabled_block_types": ["initializer_bodies", "statement_blocks"]])
        #expect(
            RuleConfigurationDescription.from(configuration: config).oneLiner()
                == "severity: warning; disabled_block_types: [initializer_bodies, statement_blocks]"
        )
    }
}
