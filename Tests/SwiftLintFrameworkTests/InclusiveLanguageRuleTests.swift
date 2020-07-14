@testable import SwiftLintFramework
import XCTest

class InclusiveLanguageRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(InclusiveLanguageRule.description)
    }

    func testNonTriggeringExamplesWithNonDefaultConfig() {
        InclusiveLanguageRuleExamples.nonTriggeringExamplesWithNonDefaultConfig.forEach { example in
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [example])
                .with(triggeringExamples: [])
            verifyRule(description, ruleConfiguration: example.configuration)
        }
    }

    func testTriggeringExamplesWithNonDefaultConfig() {
        InclusiveLanguageRuleExamples.triggeringExamplesWithNonDefaultConfig.forEach { example in
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [])
                .with(triggeringExamples: [example])
            verifyRule(description, ruleConfiguration: example.configuration)
        }
    }
}
