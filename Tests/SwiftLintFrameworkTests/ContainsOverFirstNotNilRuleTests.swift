@testable import SwiftLintFramework
import XCTest

class ContainsOverFirstNotNilRuleTests: XCTestCase {
    func testFirstReason() async throws {
        let example = Example("↓myList.first { $0 % 2 == 0 } != nil")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer `contains` over `first(where:) != nil`")
    }

    func testFirstIndexReason() async throws {
        let example = Example("↓myList.firstIndex { $0 % 2 == 0 } != nil")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer `contains` over `firstIndex(where:) != nil`")
    }

    // MARK: - Private

    private func violations(_ example: Example, config: Any? = nil) async throws -> [StyleViolation] {
        guard let config = makeConfig(config, ContainsOverFirstNotNilRule.description.identifier) else {
            return []
        }

        return try await SwiftLintFrameworkTests.violations(example, config: config)
    }
}
