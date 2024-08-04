@testable import SwiftLintBuiltInRules
import XCTest

final class XCTSpecificMatcherRuleTests: SwiftLintTestCase {
    func testEqualTrue() async {
        let example = Example("XCTAssertEqual(a, true)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testEqualFalse() async {
        let example = Example("XCTAssertEqual(a, false)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testEqualNil() async {
        let example = Example("XCTAssertEqual(a, nil)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    func testNotEqualTrue() async {
        let example = Example("XCTAssertNotEqual(a, true)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testNotEqualFalse() async {
        let example = Example("XCTAssertNotEqual(a, false)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testNotEqualNil() async {
        let example = Example("XCTAssertNotEqual(a, nil)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    // MARK: - Additional Tests

    func testEqualOptionalFalse() async {
        let example = Example("XCTAssertEqual(a?.b, false)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 0)
    }

    func testEqualUnwrappedOptionalFalse() async {
        let example = Example("XCTAssertEqual(a!.b, false)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testEqualNilNil() async {
        let example = Example("XCTAssertEqual(nil, nil)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    func testEqualTrueTrue() async {
        let example = Example("XCTAssertEqual(true, true)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testEqualFalseFalse() async {
        let example = Example("XCTAssertEqual(false, false)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testNotEqualNilNil() async {
        let example = Example("XCTAssertNotEqual(nil, nil)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    func testNotEqualTrueTrue() async {
        let example = Example("XCTAssertNotEqual(true, true)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    func testNotEqualFalseFalse() async {
        let example = Example("XCTAssertNotEqual(false, false)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    func testAssertEqual() async {
        let example = Example("XCTAssert(foo == bar)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    func testAssertFalseNotEqual() async {
        let example = Example("XCTAssertFalse(bar != foo)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    func testAssertTrueEqual() async {
        let example = Example("XCTAssertTrue(foo == 1)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    func testAssertNotEqual() async {
        let example = Example("XCTAssert(foo != bar)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotEqual' instead")
    }

    func testAssertFalseEqual() async {
        let example = Example("XCTAssertFalse(bar == foo)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotEqual' instead")
    }

    func testAssertTrueNotEqual() async {
        let example = Example("XCTAssertTrue(foo != 1)")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertNotEqual' instead")
    }

    func testMultipleComparisons() async {
        let example = Example("XCTAssert(foo == (bar == baz))")
        let violations = await self.violations(example)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    func testEqualInCommentNotConsidered() async {
        await assertNoViolation(in: "XCTAssert(foo, \"a == b\")")
    }

    func testEqualInFunctionCall() async {
        await assertNoViolation(in: "XCTAssert(foo(bar == baz))")
        await assertNoViolation(in: "XCTAssertTrue(foo(bar == baz), \"toto\")")
    }

    private func violations(_ example: Example) async -> [StyleViolation] {
        guard let config = makeConfig(nil, XCTSpecificMatcherRule.description.identifier) else { return [] }
        return await SwiftLintFrameworkTests.violations(example, config: config)
    }

    private func assertNoViolation(in example: String) async {
        let result = await violations(Example(example)).isEmpty
        XCTAssert(result)
    }
}
