@testable import SwiftLintFramework
import SwiftLintTestHelpers

final class ExtraRulesTests: SwiftLintTestCase {
    func testWithDefaultConfiguration() {
        for ruleType in extraRules() {
            verifyRule(ruleType.description)
        }
    }
}

extension ExtraRulesTests {
    static var allTests: [(String, (ExtraRulesTests) -> () throws -> Void)] {
        [("testWithDefaultConfiguration", testWithDefaultConfiguration)]
    }
}
