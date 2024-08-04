@testable import SwiftLintBuiltInRules
import XCTest

final class TodoRuleTests: SwiftLintTestCase {
    func testTodo() async {
        await verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    func testTodoMessage() async {
        let example = Example("fatalError() // TODO: Implement")
        let violations = await self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODOs should be resolved (Implement)")
    }

    func testFixMeMessage() async {
        let example = Example("fatalError() // FIXME: Implement")
        let violations = await self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "FIXMEs should be resolved (Implement)")
    }

    func testOnlyFixMe() async {
        let example = Example("""
            fatalError() // TODO: Implement todo
            fatalError() // FIXME: Implement fixme
        """)
        let violations = await self.violations(example, config: ["only": ["FIXME"]])
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "FIXMEs should be resolved (Implement fixme)")
    }

    func testOnlyTodo() async {
        let example = Example("""
            fatalError() // TODO: Implement todo
            fatalError() // FIXME: Implement fixme
        """)
        let violations = await self.violations(example, config: ["only": ["TODO"]])
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODOs should be resolved (Implement todo)")
    }

    private func violations(_ example: Example, config: Any? = nil) async -> [StyleViolation] {
        let config = makeConfig(config, TodoRule.description.identifier)!
        return await SwiftLintFrameworkTests.violations(example, config: config)
    }
}
