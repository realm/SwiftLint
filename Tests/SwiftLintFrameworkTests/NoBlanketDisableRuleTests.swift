@testable import SwiftLintFramework
import XCTest

class NoBlanketDisableRuleTests: XCTestCase {
    func testAlwaysBlanketDisable() {
        let description = NoBlanketDisablesRule.description
            .with(triggeringExamples: [])
            .with(nonTriggeringExamples: [])
        let examples = [Example("// swiftlint:disable file_length\n// swiftlint:enable file_length")]
        verifyRule(description.with(nonTriggeringExamples: examples))
        verifyRule(description.with(triggeringExamples: examples),
                   ruleConfiguration: ["always_blanket_disable": ["file_length"]],
                   skipCommentTests: true)
    }
}
