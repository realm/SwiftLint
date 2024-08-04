@testable import SwiftLintBuiltInRules
import XCTest

final class BlanketDisableCommandRuleTests: SwiftLintTestCase {
    private lazy var emptyDescription = BlanketDisableCommandRule.description
        .with(triggeringExamples: [])
        .with(nonTriggeringExamples: [])

    func testAlwaysBlanketDisable() async {
        let nonTriggeringExamples = [Example("// swiftlint:disable file_length\n// swiftlint:enable file_length")]
        await verifyRule(emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples))

        let triggeringExamples = [
            Example("// swiftlint:disable file_length\n// swiftlint:enable ↓file_length"),
            Example("// swiftlint:disable:previous ↓file_length"),
            Example("// swiftlint:disable:this ↓file_length"),
            Example("// swiftlint:disable:next ↓file_length"),
        ]
        await verifyRule(
            emptyDescription.with(triggeringExamples: triggeringExamples),
            ruleConfiguration: ["always_blanket_disable": ["file_length"]],
            skipCommentTests: true,
            skipDisableCommandTests: true
        )
    }

    func testAlwaysBlanketDisabledAreAllowed() async {
        let nonTriggeringExamples = [Example("// swiftlint:disable identifier_name\n")]
        await verifyRule(
            emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples),
            ruleConfiguration: ["always_blanket_disable": ["identifier_name"], "allowed_rules": []],
            skipDisableCommandTests: true
        )
    }

    func testAllowedRules() async {
        let nonTriggeringExamples = [
            Example("// swiftlint:disable file_length"),
            Example("// swiftlint:disable single_test_class"),
        ]
        await verifyRule(emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples))
    }
}
