@testable import SwiftLintBuiltInRules

final class CollectionAlignmentRuleTests: SwiftLintTestCase {
    func testCollectionAlignmentWithAlignLeft() async {
        let baseDescription = CollectionAlignmentRule.description
        let examples = CollectionAlignmentRule.Examples(alignColons: false)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        await verifyRule(description)
    }

    func testCollectionAlignmentWithAlignColons() async {
        let baseDescription = CollectionAlignmentRule.description
        let examples = CollectionAlignmentRule.Examples(alignColons: true)

        let description = baseDescription.with(nonTriggeringExamples: examples.nonTriggeringExamples,
                                               triggeringExamples: examples.triggeringExamples)

        await verifyRule(description, ruleConfiguration: ["align_colons": true])
    }
}
