import SwiftLintCore
import Testing

@Suite
struct ConditionallySourceKitFreeTests {
    @Test
    func requiresSourceKitForDifferentRuleTypes() {
        // SourceKitFreeRule should not require SourceKit
        let sourceKitFreeRule = MockSourceKitFreeRule()
        #expect(!sourceKitFreeRule.requiresSourceKit)

        // ConditionallySourceKitFree rule that is effectively SourceKit-free
        var conditionalRuleFree = MockConditionalRule()
        conditionalRuleFree.isEffectivelySourceKitFree = true
        #expect(!conditionalRuleFree.requiresSourceKit)

        // ConditionallySourceKitFree rule that requires SourceKit
        var conditionalRuleRequires = MockConditionalRule()
        conditionalRuleRequires.isEffectivelySourceKitFree = false
        #expect(conditionalRuleRequires.requiresSourceKit)

        // Regular rule should require SourceKit
        let regularRule = MockRegularRule()
        #expect(regularRule.requiresSourceKit)
    }

    @Test
    func typeCheckingBehavior() {
        // Verify instance-level checks work correctly
        let sourceKitFreeRule: any Rule = MockSourceKitFreeRule()
        #expect(sourceKitFreeRule is any SourceKitFreeRule)
        #expect(!(sourceKitFreeRule is any ConditionallySourceKitFree))

        let conditionalRule: any Rule = MockConditionalRule()
        #expect(!(conditionalRule is any SourceKitFreeRule))
        #expect(conditionalRule is any ConditionallySourceKitFree)

        let regularRule: any Rule = MockRegularRule()
        #expect(!(regularRule is any SourceKitFreeRule))
        #expect(!(regularRule is any ConditionallySourceKitFree))
    }
}

private struct MockConditionalRule: Rule, ConditionallySourceKitFree {
    static let description = RuleDescription(
        identifier: "mock_conditional",
        name: "Mock Conditional Rule",
        description: "A mock rule for testing ConditionallySourceKitFree",
        kind: .style
    )

    var configuration = SeverityConfiguration<Self>(.warning)
    var isEffectivelySourceKitFree = true

    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        []
    }
}

private struct MockSourceKitFreeRule: Rule, SourceKitFreeRule {
    static let description = RuleDescription(
        identifier: "mock_sourcekit_free",
        name: "Mock SourceKit Free Rule",
        description: "A mock rule that is always SourceKit-free",
        kind: .style
    )

    var configuration = SeverityConfiguration<Self>(.warning)

    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        []
    }
}

private struct MockRegularRule: Rule {
    static let description = RuleDescription(
        identifier: "mock_regular",
        name: "Mock Regular Rule",
        description: "A mock rule that requires SourceKit",
        kind: .style
    )

    var configuration = SeverityConfiguration<Self>(.warning)

    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        []
    }
}
