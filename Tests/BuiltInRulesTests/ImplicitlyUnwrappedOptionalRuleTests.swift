@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class ImplicitlyUnwrappedOptionalRuleTests: SwiftLintTestCase {
    func testImplicitlyUnwrappedOptionalRuleDefaultConfiguration() {
        let rule = ImplicitlyUnwrappedOptionalRule()
        XCTAssertEqual(rule.configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(rule.configuration.severity, .warning)
    }

    func testImplicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode() {
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

    func testImplicitlyUnwrappedOptionalRuleWarnsOnOutletsInWeakMode() {
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
