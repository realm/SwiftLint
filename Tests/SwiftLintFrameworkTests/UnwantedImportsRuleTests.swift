import SwiftLintFramework
import XCTest

class UnwantedImportsRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        let configuration = ["UIKit": "warning", "UnwantedFramework": "error"]
        verifyRule(UnwantedImportsRule.description, ruleConfiguration: configuration)
    }
}
