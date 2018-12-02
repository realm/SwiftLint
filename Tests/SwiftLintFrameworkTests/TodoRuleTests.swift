import SwiftLintFramework
import XCTest

class TodoRuleTests: XCTestCase {
    func testTodo() {
        verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    func testTodoMessage() {
        let string = "fatalError() // TODO: Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODOs should be resolved (Implement).")
    }

    func testFixMeMessage() {
        let string = "fatalError() // FIXME: Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "FIXMEs should be resolved (Implement).")
    }

    private func violations(_ string: String) -> [StyleViolation] {
        let config = makeConfig(nil, TodoRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
