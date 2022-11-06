@testable import SwiftLintBuiltInRules
import SwiftLintFramework
import XCTest

class ContainsOverFirstNotNilRuleTests: SwiftLintTestCase {
    func testFirstReason() {
        let example = Example("↓myList.first { $0 % 2 == 0 } != nil")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer `contains` over `first(where:) != nil`")
    }

    func testFirstIndexReason() {
        let example = Example("↓myList.firstIndex { $0 % 2 == 0 } != nil")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer `contains` over `firstIndex(where:) != nil`")
    }

    // MARK: - Private

    private func violations(_ example: Example, config: Any? = nil) -> [StyleViolation] {
        guard let config = makeConfig(config, ContainsOverFirstNotNilRule.description.identifier) else {
            return []
        }

        return SwiftLintFrameworkTests.violations(example, config: config)
    }
}
