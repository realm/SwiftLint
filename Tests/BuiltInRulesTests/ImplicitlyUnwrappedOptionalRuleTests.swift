import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ImplicitlyUnwrappedOptionalRuleTests {
    @Test
    func implicitlyUnwrappedOptionalRuleDefaultConfiguration() {
        let rule = ImplicitlyUnwrappedOptionalRule()
        #expect(rule.configuration.mode == .allExceptIBOutlets)
        #expect(rule.configuration.severity == .warning)
    }

    @Test
    func implicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode() {
        let baseDescription = ImplicitlyUnwrappedOptionalRule.description
        let triggeringExamples = #examples([
            "@IBOutlet private var label: UILabel!",
            "@IBOutlet var label: UILabel!",
            "let int: Int!",
        ])

        let nonTriggeringExamples = #examples(["if !boolean {}"])
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["mode": "all"],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }

    @Test
    func implicitlyUnwrappedOptionalRuleWarnsOnOutletsInWeakMode() {
        let baseDescription = ImplicitlyUnwrappedOptionalRule.description
        let triggeringExamples = #examples([
            "private weak var label: ↓UILabel!",
            "weak var label: ↓UILabel!",
            "@objc weak var label: ↓UILabel!",
        ])

        let nonTriggeringExamples = #examples([
            "@IBOutlet private var label: UILabel!",
            "@IBOutlet var label: UILabel!",
            "@IBOutlet weak var label: UILabel!",
            "var label: UILabel!",
            "let int: Int!",
        ])

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["mode": "weak_except_iboutlets"])
    }
}
