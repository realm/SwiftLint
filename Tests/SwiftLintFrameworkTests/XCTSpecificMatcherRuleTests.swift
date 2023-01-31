@testable import SwiftLintFramework
import XCTest

class XCTSpecificMatcherRuleTests: XCTestCase {
    func testEqualTrue() {
        let example = Example("XCTAssertEqual(a, true)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testEqualFalse() {
        let example = Example("XCTAssertEqual(a, false)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testEqualNil() {
        let example = Example("XCTAssertEqual(a, nil)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    func testNotEqualTrue() {
        let example = Example("XCTAssertNotEqual(a, true)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testNotEqualFalse() {
        let example = Example("XCTAssertNotEqual(a, false)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testNotEqualNil() {
        let example = Example("XCTAssertNotEqual(a, nil)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    // MARK: - Additional Tests

    func testEqualOptionalFalse() {
        let example = Example("XCTAssertEqual(a?.b, false)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 0)
    }

    func testEqualUnwrappedOptionalFalse() {
        let example = Example("XCTAssertEqual(a!.b, false)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testEqualNilNil() {
        let example = Example("XCTAssertEqual(nil, nil)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    func testEqualTrueTrue() {
        let example = Example("XCTAssertEqual(true, true)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testEqualFalseFalse() {
        let example = Example("XCTAssertEqual(false, false)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testNotEqualNilNil() {
        let example = Example("XCTAssertNotEqual(nil, nil)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    func testNotEqualTrueTrue() {
        let example = Example("XCTAssertNotEqual(true, true)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testNotEqualFalseFalse() {
        let example = Example("XCTAssertNotEqual(false, false)")
        let violations = self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    private func violations(_ example: Example) -> [StyleViolation] {
        guard let config = makeConfig(nil, XCTSpecificMatcherRule.description.identifier) else { return [] }
        return SwiftLintFrameworkTests.violations(example, config: config)
    }
}
