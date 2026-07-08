import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct XCTSpecificMatcherRuleTests {
    @Test
    func equalTrue() {
        let example = Example(code: "XCTAssertEqual(a, true)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test
    func equalFalse() {
        let example = Example(code: "XCTAssertEqual(a, false)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func equalNil() {
        let example = Example(code: "XCTAssertEqual(a, nil)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    @Test
    func notEqualTrue() {
        let example = Example(code: "XCTAssertNotEqual(a, true)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func notEqualFalse() {
        let example = Example(code: "XCTAssertNotEqual(a, false)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test
    func notEqualNil() {
        let example = Example(code: "XCTAssertNotEqual(a, nil)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    // MARK: - Additional Tests

    @Test
    func equalOptionalFalse() {
        let example = Example(code: "XCTAssertEqual(a?.b, false)")
        let violations = violations(example)

        #expect(violations.isEmpty)
    }

    @Test
    func equalUnwrappedOptionalFalse() {
        let example = Example(code: "XCTAssertEqual(a!.b, false)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func equalNilNil() {
        let example = Example(code: "XCTAssertEqual(nil, nil)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNil' instead")
    }

    @Test
    func equalTrueTrue() {
        let example = Example(code: "XCTAssertEqual(true, true)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test
    func equalFalseFalse() {
        let example = Example(code: "XCTAssertEqual(false, false)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func notEqualNilNil() {
        let example = Example(code: "XCTAssertNotEqual(nil, nil)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotNil' instead")
    }

    @Test
    func notEqualTrueTrue() {
        let example = Example(code: "XCTAssertNotEqual(true, true)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertFalse' instead")
    }

    @Test
    func notEqualFalseFalse() {
        let example = Example(code: "XCTAssertNotEqual(false, false)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertTrue' instead")
    }

    @Test
    func assertEqual() {
        let example = Example(code: "XCTAssert(foo == bar)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test
    func assertFalseNotEqual() {
        let example = Example(code: "XCTAssertFalse(bar != foo)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test
    func assertTrueEqual() {
        let example = Example(code: "XCTAssertTrue(foo == 1)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertEqual' instead")
    }

    @Test
    func assertNotEqual() {
        let example = Example(code: "XCTAssert(foo != bar)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead")
    }

    @Test
    func assertFalseEqual() {
        let example = Example(code: "XCTAssertFalse(bar == foo)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead")
    }

    @Test
    func assertTrueNotEqual() {
        let example = Example(code: "XCTAssertTrue(foo != 1)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotEqual' instead")
    }

    @Test
    func multipleComparisons() {
        let example = Example(code: "XCTAssert(foo == (bar == baz))")
        let violations = violations(example)

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
        let example = Example(code: "XCTAssert(foo === bar)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertIdentical' instead")
    }

    @Test
    func assertNotIdentical() {
        let example = Example(code: "XCTAssert(foo !== bar)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead")
    }

    @Test
    func assertTrueIdentical() {
        let example = Example(code: "XCTAssertTrue(foo === bar)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertIdentical' instead")
    }

    @Test
    func assertTrueNotIdentical() {
        let example = Example(code: "XCTAssertTrue(foo !== bar)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead")
    }

    @Test
    func assertFalseIdentical() {
        let example = Example(code: "XCTAssertFalse(foo === bar)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertNotIdentical' instead")
    }

    @Test
    func assertFalseNotIdentical() {
        let example = Example(code: "XCTAssertFalse(foo !== bar)")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer the specific matcher 'XCTAssertIdentical' instead")
    }

    private func violations(_ example: Example) -> [StyleViolation] {
        guard let config = makeConfig(nil, XCTSpecificMatcherRule.identifier) else { return [] }
        return TestHelpers.violations(example, config: config)
    }

    private func noViolation(in example: String) -> Bool {
        violations(Example(code: example)).isEmpty
    }
}
