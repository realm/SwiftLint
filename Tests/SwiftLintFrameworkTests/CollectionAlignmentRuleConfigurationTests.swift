@testable import SwiftLintFramework
import XCTest

// swiftlint:disable:next type_name
class CollectionAlignmentRuleConfigurationTests: XCTestCase {
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
