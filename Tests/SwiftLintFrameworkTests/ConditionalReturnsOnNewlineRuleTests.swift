@testable import SwiftLintFramework
import XCTest

class ConditionalReturnsOnNewlineRuleTests: XCTestCase {
    func testConditionalReturnsOnNewlineWithIfOnly() async throws {
        // Test with `if_only` set to true
        let nonTriggeringExamples = [
            Example("guard true else {\n return true\n}"),
            Example("guard true,\n let x = true else {\n return true\n}"),
            Example("if true else {\n return true\n}"),
            Example("if true,\n let x = true else {\n return true\n}"),
            Example("if textField.returnKeyType == .Next {"),
            Example("if true { // return }"),
            Example("/*if true { */ return }"),
            Example("guard true else { return }")
        ]
        let triggeringExamples = [
            Example("↓if true { return }"),
            Example("↓if true { break } else { return }"),
            Example("↓if true { break } else {       return }"),
            Example("↓if true { return \"YES\" } else { return \"NO\" }")
        ]

        let description = ConditionalReturnsOnNewlineRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["if_only": true])
    }
}
