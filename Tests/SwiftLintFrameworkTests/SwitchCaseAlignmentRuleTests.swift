@testable import SwiftLintFramework
import XCTest

class SwitchCaseAlignmentRuleTests: XCTestCase {
    func testSwitchCaseAlignmentWithoutIndentedCases() async throws {
        let baseDescription = SwitchCaseAlignmentRule.description
        let examples = SwitchCaseAlignmentRule.Examples(indentedCases: false)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        try await verifyRule(description)
    }

    func testSwitchCaseAlignmentWithIndentedCases() async throws {
        let baseDescription = SwitchCaseAlignmentRule.description
        let examples = SwitchCaseAlignmentRule.Examples(indentedCases: true)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["indented_cases": true])
    }
}
