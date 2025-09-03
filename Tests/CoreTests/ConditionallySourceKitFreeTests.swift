@testable import SwiftLintCore
import XCTest

final class ConditionallySourceKitFreeTests: XCTestCase {
    // Mock rule for testing ConditionallySourceKitFree protocol
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

    func testRequiresSourceKitForDifferentRuleTypes() {
        // SourceKitFreeRule should not require SourceKit
        let sourceKitFreeRule = MockSourceKitFreeRule()
        XCTAssertFalse(sourceKitFreeRule.requiresSourceKit)

        // ConditionallySourceKitFree rule that is effectively SourceKit-free
        var conditionalRuleFree = MockConditionalRule()
        conditionalRuleFree.isEffectivelySourceKitFree = true
        XCTAssertFalse(conditionalRuleFree.requiresSourceKit)

        // ConditionallySourceKitFree rule that requires SourceKit
        var conditionalRuleRequires = MockConditionalRule()
        conditionalRuleRequires.isEffectivelySourceKitFree = false
        XCTAssertTrue(conditionalRuleRequires.requiresSourceKit)

        // Regular rule should require SourceKit
        let regularRule = MockRegularRule()
        XCTAssertTrue(regularRule.requiresSourceKit)
    }

    func testTypeCheckingBehavior() {
        // Verify instance-level checks work correctly
        let sourceKitFreeRule: any Rule = MockSourceKitFreeRule()
        XCTAssertTrue(sourceKitFreeRule is any SourceKitFreeRule)
        XCTAssertFalse(sourceKitFreeRule is any ConditionallySourceKitFree)

        let conditionalRule: any Rule = MockConditionalRule()
        XCTAssertFalse(conditionalRule is any SourceKitFreeRule)
        XCTAssertTrue(conditionalRule is any ConditionallySourceKitFree)

        let regularRule: any Rule = MockRegularRule()
        XCTAssertFalse(regularRule is any SourceKitFreeRule)
        XCTAssertFalse(regularRule is any ConditionallySourceKitFree)
    }
}
