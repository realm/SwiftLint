import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct XCTSpecificMatcherRuleTests {
    @Test
    func equalTrue() {
        let example = Example("XCTAssertEqual(a, true)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test
    func equalFalse() {
        let example = Example("XCTAssertEqual(a, false)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func equalNil() {
        let example = Example("XCTAssertEqual(a, nil)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    @Test
    func notEqualTrue() {
        let example = Example("XCTAssertNotEqual(a, true)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func notEqualFalse() {
        let example = Example("XCTAssertNotEqual(a, false)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test
    func notEqualNil() {
        let example = Example("XCTAssertNotEqual(a, nil)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    // MARK: - Additional Tests

    @Test
    func equalOptionalFalse() {
        let example = Example("XCTAssertEqual(a?.b, false)")
        let violations = self.violations(example)

        #expect(violations.isEmpty)
    }

    @Test
    func equalUnwrappedOptionalFalse() {
        let example = Example("XCTAssertEqual(a!.b, false)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func equalNilNil() {
        let example = Example("XCTAssertEqual(nil, nil)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    @Test
    func equalTrueTrue() {
        let example = Example("XCTAssertEqual(true, true)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test
    func equalFalseFalse() {
        let example = Example("XCTAssertEqual(false, false)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func notEqualNilNil() {
        let example = Example("XCTAssertNotEqual(nil, nil)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    @Test
    func notEqualTrueTrue() {
        let example = Example("XCTAssertNotEqual(true, true)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func notEqualFalseFalse() {
        let example = Example("XCTAssertNotEqual(false, false)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test
    func assertEqual() {
        let example = Example("XCTAssert(foo == bar)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test
    func assertFalseNotEqual() {
        let example = Example("XCTAssertFalse(bar != foo)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test
    func assertTrueEqual() {
        let example = Example("XCTAssertTrue(foo == 1)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test
    func assertNotEqual() {
        let example = Example("XCTAssert(foo != bar)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead")
    }

    @Test
    func assertFalseEqual() {
        let example = Example("XCTAssertFalse(bar == foo)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead")
    }

    @Test
    func assertTrueNotEqual() {
        let example = Example("XCTAssertTrue(foo != 1)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead")
    }

    @Test
    func multipleComparisons() {
        let example = Example("XCTAssert(foo == (bar == baz))")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test
    func equalInCommentNotConsidered() {
        #expect(noViolation(in: "XCTAssert(foo, \"a == b\")"))
    }

    @Test
    func equalInFunctionCall() {
        #expect(noViolation(in: "XCTAssert(foo(bar == baz))"))
        #expect(noViolation(in: "XCTAssertTrue(foo(bar == baz), \"toto\")"))
    }

    // MARK: - Identity Operator Tests

    @Test
    func assertIdentical() {
        let example = Example("XCTAssert(foo === bar)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertIdentical' instead")
    }

    @Test
    func assertNotIdentical() {
        let example = Example("XCTAssert(foo !== bar)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead")
    }

    @Test
    func assertTrueIdentical() {
        let example = Example("XCTAssertTrue(foo === bar)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertIdentical' instead")
    }

    @Test
    func assertTrueNotIdentical() {
        let example = Example("XCTAssertTrue(foo !== bar)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead")
    }

    @Test
    func assertFalseIdentical() {
        let example = Example("XCTAssertFalse(foo === bar)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead")
    }

    @Test
    func assertFalseNotIdentical() {
        let example = Example("XCTAssertFalse(foo !== bar)")
        let violations = self.violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertIdentical' instead")
    }

    private func violations(_ example: Example) -> [StyleViolation] {
        guard let config = makeConfig(nil, XCTSpecificMatcherRule.identifier) else { return [] }
        return TestHelpers.violations(example, config: config)
    }

    private func noViolation(in example: String) -> Bool {
        violations(Example(example)).isEmpty
    }
}
