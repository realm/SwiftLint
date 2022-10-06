@testable import SwiftLintFramework
import XCTest

final class ExtraRulesTests: XCTestCase {
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
