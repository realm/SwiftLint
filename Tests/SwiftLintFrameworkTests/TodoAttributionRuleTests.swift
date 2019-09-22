import SwiftLintFramework
import XCTest

class TodoAttributionRuleTests: XCTestCase {
    func testTodoAttribution() {
        verifyRule(TodoAttributionRule.description, commentDoesntViolate: false)
    }

    func testTodoMessage() {
        let string = "fatalError() // TODO: Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        let expected = "TODOs should be attributed to "
            + "their owner (e.g. 'TODO: @gituser') "
            + "or related issue (e.g. 'TODO: #2871')."
        XCTAssertEqual(violations.first!.reason, expected)
    }

    func testFixmeMessage() {
        let string = "fatalError() // FIXME: Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        let expected = "FIXMEs should be attributed to "
        + "their owner (e.g. 'FIXME: @gituser') "
        + "or related issue (e.g. 'FIXME: #2871')."
        XCTAssertEqual(violations.first!.reason, expected)
    }

    func testOwnerExpectedFormatMessage() {
        let string = "fatalError() // FIXME: Implement @gituser"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        let expected = "Expected FIXME format is: 'FIXME: @owner_handle'."
        XCTAssertEqual(violations.first!.reason, expected)
    }

    func testIssueExpectedFormatMessage() {
        let string = "fatalError() // TO-DO: #2871 Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        let expected = "Expected TODO format is: 'TODO: #issue_identifier'."
        XCTAssertEqual(violations.first!.reason, expected)
    }

    func testIssueAndOwnerExpectedFormatMessage() {
        let string = "fatalError() // fixme: @gituser #2871 Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        let expected = "Expected FIXME format is: 'FIXME: @owner_handle #issue_identifier'."
        XCTAssertEqual(violations.first!.reason, expected)
    }

    private func violations(_ string: String) -> [StyleViolation] {
        let config = makeConfig(nil, TodoAttributionRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
