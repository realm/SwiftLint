@testable import SwiftLintExtraRules
import SwiftLintTestHelpers

final class ExtraRulesTests: SwiftLintTestCase {
    func testWithDefaultConfiguration() async {
        for ruleType in extraRules() {
            await verifyRule(ruleType.description)
        }
    }
}

extension ExtraRulesTests {
    static var allTests: [(String, (ExtraRulesTests) -> () async throws -> Void)] {
        [("testWithDefaultConfiguration", testWithDefaultConfiguration)]
    }
}
