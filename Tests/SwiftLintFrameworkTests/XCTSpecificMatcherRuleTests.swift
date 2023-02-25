@testable import SwiftLintFramework
import XCTest

class XCTSpecificMatcherRuleTests: XCTestCase {
    func testEqualTrue() async throws {
        let example = Example("XCTAssertEqual(a, true)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testEqualFalse() async throws {
        let example = Example("XCTAssertEqual(a, false)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testEqualNil() async throws {
        let example = Example("XCTAssertEqual(a, nil)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    func testNotEqualTrue() async throws {
        let example = Example("XCTAssertNotEqual(a, true)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testNotEqualFalse() async throws {
        let example = Example("XCTAssertNotEqual(a, false)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testNotEqualNil() async throws {
        let example = Example("XCTAssertNotEqual(a, nil)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    // MARK: - Additional Tests

    func testEqualOptionalFalse() async throws {
        let example = Example("XCTAssertEqual(a?.b, false)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 0)
    }

    func testEqualUnwrappedOptionalFalse() async throws {
        let example = Example("XCTAssertEqual(a!.b, false)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testEqualNilNil() async throws {
        let example = Example("XCTAssertEqual(nil, nil)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    func testEqualTrueTrue() async throws {
        let example = Example("XCTAssertEqual(true, true)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testEqualFalseFalse() async throws {
        let example = Example("XCTAssertEqual(false, false)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testNotEqualNilNil() async throws {
        let example = Example("XCTAssertNotEqual(nil, nil)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    func testNotEqualTrueTrue() async throws {
        let example = Example("XCTAssertNotEqual(true, true)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testNotEqualFalseFalse() async throws {
        let example = Example("XCTAssertNotEqual(false, false)")
        let violations = try await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    private func violations(_ example: Example) async throws -> [StyleViolation] {
        guard let config = makeConfig(nil, XCTSpecificMatcherRule.description.identifier) else { return [] }
        return try await SwiftLintFrameworkTests.violations(example, config: config)
    }
}
