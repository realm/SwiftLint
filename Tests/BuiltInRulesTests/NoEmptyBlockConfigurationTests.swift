@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import TestHelpers
import XCTest

final class NoEmptyBlockConfigurationTests: SwiftLintTestCase {
    func testDefaultConfiguration() {
        let config = NoEmptyBlockConfiguration()
        XCTAssertEqual(config.severityConfiguration.severity, .warning)
        XCTAssertEqual(config.enabledBlockTypes, NoEmptyBlockConfiguration.CodeBlockType.all)
    }

    func testApplyingCustomConfiguration() throws {
        var config = NoEmptyBlockConfiguration()
        try config.apply(
            configuration: [
                "severity": "error",
                "disabled_block_types": ["function_bodies"],
            ] as [String: any Sendable]
        )
        XCTAssertEqual(config.severityConfiguration.severity, .error)
        XCTAssertEqual(config.enabledBlockTypes, Set([.initializerBodies, .statementBlocks, .closureBlocks]))
    }

    @MainActor
    func testInvalidKeyInCustomConfiguration() async throws {
        var config = NoEmptyBlockConfiguration()
        try await AsyncAssertEqual(
            try await Issue.captureConsole { try config.apply(configuration: ["invalidKey": "error"]) },
            "warning: Configuration for 'no_empty_block' rule contains the invalid key(s) 'invalidKey'."
        )
    }

    func testInvalidTypeOfCustomConfiguration() {
        var config = NoEmptyBlockConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: NoEmptyBlockRule.identifier)) {
            try config.apply(configuration: "invalidKey")
        }
    }

    func testInvalidTypeOfValueInCustomConfiguration() {
        var config = NoEmptyBlockConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: NoEmptyBlockRule.identifier)) {
            try config.apply(configuration: ["severity": "foo"])
        }
    }

    func testConsoleDescription() throws {
        var config = NoEmptyBlockConfiguration()
        try config.apply(configuration: ["disabled_block_types": ["initializer_bodies", "statement_blocks"]])
        XCTAssertEqual(
            RuleConfigurationDescription.from(configuration: config).oneLiner(),
            "severity: warning; disabled_block_types: [initializer_bodies, statement_blocks]"
        )
    }
}
