@testable import SwiftLintFramework
import XCTest

class TrailingWhitespaceRuleTests: XCTestCase {
    func testWithIgnoresEmptyLinesEnabled() async throws {
        // Perform additional tests with the ignores_empty_lines setting enabled.
        // The set of non-triggering examples is extended by a whitespace-indented empty line
        let baseDescription = TrailingWhitespaceRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [Example(" \n")]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)

        try await verifyRule(description,
                             ruleConfiguration: ["ignores_empty_lines": true, "ignores_comments": true])
    }

    func testWithIgnoresCommentsDisabled() async throws {
        // Perform additional tests with the ignores_comments settings disabled.
        let baseDescription = TrailingWhitespaceRule.description
        let triggeringComments = [
            Example("// \n"),
            Example("let name: String // \n")
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
            .filter { !triggeringComments.contains($0) }
        let triggeringExamples = baseDescription.triggeringExamples + triggeringComments
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)
        try await verifyRule(description,
                             ruleConfiguration: ["ignores_empty_lines": false, "ignores_comments": false],
                             commentDoesntViolate: false)
    }
}
