import SwiftLintFramework
import XCTest

class XCTSpecificMatcherRuleTests: XCTestCase {
    func testRule() {
        verifyRule(XCTSpecificMatcherRule.description)
    }

    // MARK: - Reasons

    func testEqualTrue() {
        let string = "XCTAssertEqual(a, true)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead.")
    }

    func testEqualFalse() {
        let string = "XCTAssertEqual(a, false)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead.")
    }

    func testEqualNil() {
        let string = "XCTAssertEqual(a, nil)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNil' instead.")
    }

    func testNotEqualTrue() {
        let string = "XCTAssertNotEqual(a, true)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead.")
    }

    func testNotEqualFalse() {
        let string = "XCTAssertNotEqual(a, false)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead.")
    }

    func testNotEqualNil() {
        let string = "XCTAssertNotEqual(a, nil)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotNil' instead.")
    }

    // MARK: - Additional Tests

    func testEqualOptionalFalse() {
        let string = "XCTAssertEqual(a?.b, false)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 0)
    }

    func testEqualUnwrappedOptionalFalse() {
        let string = "XCTAssertEqual(a!.b, false)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead.")
    }

    func testEqualNilNil() {
        let string = "XCTAssertEqual(nil, nil)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNil' instead.")
    }

    func testEqualTrueTrue() {
        let string = "XCTAssertEqual(true, true)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead.")
    }

    func testEqualFalseFalse() {
        let string = "XCTAssertEqual(false, false)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead.")
    }

    func testNotEqualNilNil() {
        let string = "XCTAssertNotEqual(nil, nil)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotNil' instead.")
    }

    func testNotEqualTrueTrue() {
        let string = "XCTAssertNotEqual(true, true)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead.")
    }

    func testNotEqualFalseFalse() {
        let string = "XCTAssertNotEqual(false, false)"
        let violations = self.violations(string)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead.")
    }

    private func violations(_ string: String) -> [StyleViolation] {
        guard let config = makeConfig(nil, XCTSpecificMatcherRule.description.identifier) else { return [] }
        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
