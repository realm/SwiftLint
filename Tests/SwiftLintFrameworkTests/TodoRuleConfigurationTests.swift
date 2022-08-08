import SwiftLintFramework
import XCTest

class TodoRuleConfigurationTests: XCTestCase {
    func testTodo() async {
        await verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    func testTodoMessage() async {
        let example = Example("fatalError() // TODO: Implement")
        let violations = await self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODOs should be resolved (Implement).")
    }

    func testFixMeMessage() async {
        let example = Example("fatalError() // FIXME: Implement")
        let violations = await self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "FIXMEs should be resolved (Implement).")
    }

    private func violations(_ example: Example) async -> [StyleViolation] {
        let config = makeConfig(nil, TodoRule.description.identifier)!
        return await SwiftLintFrameworkTests.violations(example, config: config)
    }
}
