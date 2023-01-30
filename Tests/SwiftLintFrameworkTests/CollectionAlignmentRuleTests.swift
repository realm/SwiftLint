@testable import SwiftLintFramework
import XCTest

class CollectionAlignmentRuleTests: XCTestCase {
    func testCollectionAlignmentWithAlignLeft() async throws {
        let baseDescription = CollectionAlignmentRule.description
        let examples = CollectionAlignmentRule.Examples(alignColons: false)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        try await verifyRule(description)
    }

    func testCollectionAlignmentWithAlignColons() async throws {
        let baseDescription = CollectionAlignmentRule.description
        let examples = CollectionAlignmentRule.Examples(alignColons: true)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["align_colons": true])
    }
}
