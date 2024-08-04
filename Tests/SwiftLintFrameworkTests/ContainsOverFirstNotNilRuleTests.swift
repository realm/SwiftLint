@testable import SwiftLintBuiltInRules
import XCTest

final class ContainsOverFirstNotNilRuleTests: SwiftLintTestCase {
    func testFirstReason() async {
        let example = Example("↓myList.first { $0 % 2 == 0 } != nil")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer `contains` over `first(where:) != nil`")
    }

    func testFirstIndexReason() async {
        let example = Example("↓myList.firstIndex { $0 % 2 == 0 } != nil")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer `contains` over `firstIndex(where:) != nil`")
    }

    // MARK: - Private

    private func violations(_ example: Example, config: Any? = nil) async -> [StyleViolation] {
        guard let config = makeConfig(config, ContainsOverFirstNotNilRule.description.identifier) else {
            return []
        }

        return await SwiftLintFrameworkTests.violations(example, config: config)
    }
}
