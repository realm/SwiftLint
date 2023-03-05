@testable import SwiftLintFramework
import XCTest

class BlanketDisableCommandRuleTests: XCTestCase {
    private var emptyDescription: RuleDescription {
        BlanketDisableCommandRule.description.with(triggeringExamples: []).with(nonTriggeringExamples: [])
    }

    func testAlwaysBlanketDisable() {
        let nonTriggeringExamples = [Example("// swiftlint:disable file_length\n// swiftlint:enable file_length")]
        verifyRule(emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples))

        let triggeringExamples = [
            Example("// swiftlint:disable file_length\n// swiftlint:enable ↓file_length"),
            Example("// swiftlint:disable:previous ↓file_length"),
            Example("// swiftlint:disable:this ↓file_length"),
            Example("// swiftlint:disable:next ↓file_length")
        ]
        verifyRule(emptyDescription.with(triggeringExamples: triggeringExamples),
                   ruleConfiguration: ["always_blanket_disable": ["file_length"]],
                   skipCommentTests: true, skipDisableCommandTests: true)
    }

    func testAlwaysBlanketDisabledAreAllowed() {
        let nonTriggeringExamples = [Example("// swiftlint:disable identifier_name\n")]
        verifyRule(emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples),
                   ruleConfiguration: ["always_blanket_disable": ["identifier_name"], "allowed_rules": []],
                   skipDisableCommandTests: true)
    }

    func testAllowedRules() {
        let nonTriggeringExamples = [
            Example("// swiftlint:disable file_length"),
            Example("// swiftlint:disable single_test_class")
        ]
        verifyRule(emptyDescription.with(nonTriggeringExamples: nonTriggeringExamples))
    }
}
