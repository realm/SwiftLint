@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class ContainsOverFirstNotNilRuleTests: SwiftLintTestCase {
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
        guard let config = makeConfig(config, ContainsOverFirstNotNilRule.identifier) else {
            return []
        }

        return TestHelpers.violations(example, config: config)
    }
}
