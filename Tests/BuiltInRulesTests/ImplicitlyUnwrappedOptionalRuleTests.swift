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
        let triggeringExamples = [
            Example("@IBOutlet private var label: UILabel!"),
            Example("@IBOutlet var label: UILabel!"),
            Example("let int: Int!"),
        ]

        let nonTriggeringExamples = [Example("if !boolean {}")]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["mode": "all"],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }

    @Test
    func implicitlyUnwrappedOptionalRuleWarnsOnOutletsInWeakMode() {
        let baseDescription = ImplicitlyUnwrappedOptionalRule.description
        let triggeringExamples = [
            Example("private weak var label: ↓UILabel!"),
            Example("weak var label: ↓UILabel!"),
            Example("@objc weak var label: ↓UILabel!"),
        ]

        let nonTriggeringExamples = [
            Example("@IBOutlet private var label: UILabel!"),
            Example("@IBOutlet var label: UILabel!"),
            Example("@IBOutlet weak var label: UILabel!"),
            Example("var label: UILabel!"),
            Example("let int: Int!"),
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["mode": "weak_except_iboutlets"])
    }
}
