@testable import SwiftLintFramework

class PrivateOverFilePrivateRuleTests: SwiftLintTestCase {
    func testPrivateOverFilePrivateValidatingExtensions() {
        let baseDescription = PrivateOverFilePrivateRule.description
        let triggeringExamples = baseDescription.triggeringExamples + [
            Example("↓fileprivate extension String {}"),
            Example("↓fileprivate \n extension String {}"),
            Example("↓fileprivate extension \n String {}")
        ]
        let corrections = [
            Example("↓fileprivate extension String {}"): Example("private extension String {}"),
            Example("↓fileprivate \n extension String {}"): Example("private \n extension String {}"),
            Example("↓fileprivate extension \n String {}"): Example("private extension \n String {}")
        ]

        let description = baseDescription.with(nonTriggeringExamples: [])
            .with(triggeringExamples: triggeringExamples).with(corrections: corrections)
        verifyRule(description, ruleConfiguration: ["validate_extensions": true])
    }

    func testPrivateOverFilePrivateNotValidatingExtensions() {
        let baseDescription = PrivateOverFilePrivateRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("fileprivate extension String {}")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["validate_extensions": false])
    }
}
