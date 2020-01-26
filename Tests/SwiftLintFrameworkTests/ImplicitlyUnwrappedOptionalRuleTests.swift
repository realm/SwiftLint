@testable import SwiftLintFramework
import XCTest

class ImplicitlyUnwrappedOptionalRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(ImplicitlyUnwrappedOptionalRule.description)
    }

    func testImplicitlyUnwrappedOptionalRuleDefaultConfiguration() {
        let rule = ImplicitlyUnwrappedOptionalRule()
        XCTAssertEqual(rule.configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(rule.configuration.severity.severity, .warning)
    }

    func testImplicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode() {
        let baseDescription = ImplicitlyUnwrappedOptionalRule.description
        let triggeringExamples = [
            Example("@IBOutlet private var label: UILabel!"),
            Example("@IBOutlet var label: UILabel!"),
            Example("let int: Int!")
        ]

        let nonTriggeringExamples = [Example("if !boolean {}")]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["mode": "all"],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }
}
