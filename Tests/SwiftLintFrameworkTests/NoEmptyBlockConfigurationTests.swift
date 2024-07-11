@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
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
                "disabled": ["function_bodies", "accessor_bodies"],
            ] as [String: any Sendable]
        )
        XCTAssertEqual(config.severityConfiguration.severity, .error)
        XCTAssertEqual(config.enabledBlockTypes, Set([.initializerBodies, .statementBlocks]))
    }

    func testInvalidKeyInCustomConfiguration() {
        var config = NoEmptyBlockConfiguration()
        XCTAssertEqual(
            try Issue.captureConsole { try config.apply(configuration: ["invalidKey": "error"]) },
            "warning: Configuration for 'no_empty_block' rule contains the invalid key(s) 'invalidKey'."
        )
    }

    func testInvalidTypeOfCustomConfiguration() {
        var config = NoEmptyBlockConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: NoEmptyBlockRule.description.identifier)) {
            try config.apply(configuration: "invalidKey")
        }
    }

    func testInvalidTypeOfValueInCustomConfiguration() {
        var config = NoEmptyBlockConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: NoEmptyBlockRule.description.identifier)) {
            try config.apply(configuration: ["severity": "foo"])
        }
    }

    func testConsoleDescription() throws {
        var config = NoEmptyBlockConfiguration()
        try config.apply(configuration: ["disabled": ["initializer_bodies", "statement_blocks"]])
        XCTAssertEqual(
            RuleConfigurationDescription.from(configuration: config).oneLiner(),
            "severity: warning; disabled: [initializer_bodies, statement_blocks]"
        )
    }
}
