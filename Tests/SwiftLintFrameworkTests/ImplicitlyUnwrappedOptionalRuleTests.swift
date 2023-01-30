@testable import SwiftLintFramework
import XCTest

class ImplicitlyUnwrappedOptionalRuleTests: XCTestCase {
    func testImplicitlyUnwrappedOptionalRuleDefaultConfiguration() {
        let rule = ImplicitlyUnwrappedOptionalRule()
        XCTAssertEqual(rule.configuration.mode, .allExceptIBOutlets)
        XCTAssertEqual(rule.configuration.severity, .warning)
    }

    func testImplicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode() async throws {
        let baseDescription = ImplicitlyUnwrappedOptionalRule.description
        let triggeringExamples = [
            Example("@IBOutlet private var label: UILabel!"),
            Example("@IBOutlet var label: UILabel!"),
            Example("let int: Int!")
        ]

        let nonTriggeringExamples = [Example("if !boolean {}")]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        try await verifyRule(description, ruleConfiguration: ["mode": "all"],
                             commentDoesntViolate: true, stringDoesntViolate: true)
    }
}
