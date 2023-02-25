@testable import SwiftLintFramework
import SwiftLintTestHelpers
import XCTest

final class ExtraRulesTests: XCTestCase {
    func testWithDefaultConfiguration() async throws {
        for ruleType in extraRules() {
            try await verifyRule(ruleType.description)
        }
    }
}

extension ExtraRulesTests {
    static var allTests: [(String, (ExtraRulesTests) -> () async throws -> Void)] {
        [("testWithDefaultConfiguration", testWithDefaultConfiguration)]
    }
}
