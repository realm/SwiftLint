@testable import SwiftLintFramework
import XCTest

class TodoRuleTests: SwiftLintTestCase {
    func testTodo() {
        verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    func testTodoMessage() {
        let example = Example("fatalError() // TODO: Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODOs should be resolved (Implement).")
    }

    func testFixMeMessage() {
        let example = Example("fatalError() // FIXME: Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "FIXMEs should be resolved (Implement).")
    }

    private func violations(_ example: Example) -> [StyleViolation] {
        let config = makeConfig(nil, TodoRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(example, config: config)
    }
}
