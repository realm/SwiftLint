@testable import SwiftLintFramework
import XCTest

class NoBlanketDisableRuleTests: XCTestCase {
    func testAlwaysBlanketDisable() {
        let description = NoBlanketDisablesRule.description
            .with(triggeringExamples: [])
            .with(nonTriggeringExamples: [])

        let nonTriggeringExamples = [Example("// swiftlint:disable file_length\n// swiftlint:enable file_length")]
        verifyRule(description.with(nonTriggeringExamples: nonTriggeringExamples))

        let triggeringExamples = nonTriggeringExamples + [
            Example("// swiftlint:disable:previous file_length"),
            Example("// swiftlint:disable:this file_length"),
            Example("// swiftlint:disable:next file_length")
        ]
        verifyRule(description.with(triggeringExamples: triggeringExamples),
                   ruleConfiguration: ["always_blanket_disable": ["file_length"]],
                   skipCommentTests: true)
    }
}
