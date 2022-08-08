@testable import SwiftLintFramework
import XCTest

class CollectionAlignmentRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(CollectionAlignmentRule.description)
    }

    func testCollectionAlignmentWithAlignLeft() {
        let baseDescription = CollectionAlignmentRule.description
        let examples = CollectionAlignmentRule.Examples(alignColons: false)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        verifyRule(description)
    }

    func testCollectionAlignmentWithAlignColons() {
        let baseDescription = CollectionAlignmentRule.description
        let examples = CollectionAlignmentRule.Examples(alignColons: true)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        verifyRule(description, ruleConfiguration: ["align_colons": true])
    }
}
