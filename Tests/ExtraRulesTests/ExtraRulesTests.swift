import TestHelpers
import Testing

@testable import SwiftLintExtraRules

@Suite
struct ExtraRulesTests {
    @Test
    func withDefaultConfiguration() {
        for ruleType in extraRules() {
            verifyRule(ruleType.description)
        }
    }
}

extension ExtraRulesTests {
    static var allTests: [(String, (ExtraRulesTests) -> () throws -> Void)] {
        [("testWithDefaultConfiguration", withDefaultConfiguration)]
    }
}
