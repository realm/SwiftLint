@testable import SwiftLintFramework
import XCTest

class InclusiveLanguageRuleTests: XCTestCase {
    func testWithDefaultConfiguration() async {
        await verifyRule(InclusiveLanguageRule.description)
    }

    func testNonTriggeringExamplesWithNonDefaultConfig() async {
        for example in InclusiveLanguageRuleExamples.nonTriggeringExamplesWithConfig {
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [example])
                .with(triggeringExamples: [])
            await verifyRule(description, ruleConfiguration: example.configuration)
        }
    }

    func testTriggeringExamplesWithNonDefaultConfig() async {
        for example in InclusiveLanguageRuleExamples.triggeringExamplesWithConfig {
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [])
                .with(triggeringExamples: [example])
            await verifyRule(description, ruleConfiguration: example.configuration)
        }
    }
}
