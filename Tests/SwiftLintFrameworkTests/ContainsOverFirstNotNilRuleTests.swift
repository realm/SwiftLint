import SwiftLintFramework
import XCTest

class ContainsOverFirstNotNilRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(ContainsOverFirstNotNilRule.description)
    }

    // MARK: - Reasons

    func testFirstReason() {
        let string = "↓myList.first { $0 % 2 == 0 } != nil"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer `contains` over `first(where:) != nil`")
    }

    func testFirstIndexReason() {
        let string = "↓myList.firstIndex { $0 % 2 == 0 } != nil"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer `contains` over `firstIndex(where:) != nil`")
    }

    // MARK: - Private

    private func violations(_ string: String, config: Any? = nil) -> [StyleViolation] {
        guard let config = makeConfig(config, ContainsOverFirstNotNilRule.description.identifier) else {
            return []
        }

        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
