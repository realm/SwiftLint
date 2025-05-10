@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class TodoRuleTests: SwiftLintTestCase {
    func testTodo() {
        verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    func testTodoMessage() {
        let example = Example("fatalError() // TODO: Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODOs should be resolved (Implement)")
    }

    func testFixMeMessage() {
        let example = Example("fatalError() // FIXME: Implement")
        let violations = self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "FIXMEs should be resolved (Implement)")
    }

    func testOnlyFixMe() {
        let example = Example("""
            fatalError() // TODO: Implement todo
            fatalError() // FIXME: Implement fixme
        """)
        let violations = self.violations(example, config: ["only": ["FIXME"]])
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "FIXMEs should be resolved (Implement fixme)")
    }

    func testOnlyTodo() {
        let example = Example("""
            fatalError() // TODO: Implement todo
            fatalError() // FIXME: Implement fixme
        """)
        let violations = self.violations(example, config: ["only": ["TODO"]])
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODOs should be resolved (Implement todo)")
    }

    private func violations(_ example: Example, config: Any? = nil) -> [StyleViolation] {
        let config = makeConfig(config, TodoRule.identifier)!
        return TestHelpers.violations(example, config: config)
    }
}
