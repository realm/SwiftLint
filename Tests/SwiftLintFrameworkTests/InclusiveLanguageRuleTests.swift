@testable import SwiftLintFramework
import XCTest

class InclusiveLanguageRuleTests: XCTestCase {
    func testNonTriggeringExamplesWithNonDefaultConfig() async throws {
        for example in InclusiveLanguageRuleExamples.nonTriggeringExamplesWithConfig {
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [example])
                .with(triggeringExamples: [])
            try await verifyRule(description, ruleConfiguration: example.configuration)
        }
    }

    func testTriggeringExamplesWithNonDefaultConfig() async throws {
        for example in InclusiveLanguageRuleExamples.triggeringExamplesWithConfig {
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [])
                .with(triggeringExamples: [example])
            try await verifyRule(description, ruleConfiguration: example.configuration)
        }
    }
}
