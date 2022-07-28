@testable import SwiftLintFramework
import XCTest

final class ExtraRulesTests: XCTestCase {
    func testWithDefaultConfiguration() {
        for ruleType in extraRules() {
            verifyRule(ruleType.description)
        }
    }
}
