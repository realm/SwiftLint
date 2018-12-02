import Foundation
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
            "@IBOutlet private var label: UILabel!",
            "@IBOutlet var label: UILabel!",
            "let int: Int!"
        ]

        let nonTriggeringExamples = ["if !boolean {}"]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["mode": "all"],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }
}
