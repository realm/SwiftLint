@testable import SwiftLintFramework
import XCTest

final class ExtraRulesTests: XCTestCase {
    func testWithDefaultConfiguration() async {
        for ruleType in extraRules() {
            await verifyRule(ruleType.description)
        }
    }
}

extension ExtraRulesTests {
    // swiftlint:disable:next void_return
    static var allTests: [(String, (ExtraRulesTests) -> () async throws -> Void)] {
        [("testWithDefaultConfiguration", testWithDefaultConfiguration)]
    }
}
