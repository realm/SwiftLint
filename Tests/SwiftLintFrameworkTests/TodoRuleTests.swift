@testable import SwiftLintFramework
import XCTest

class TodoRuleTests: XCTestCase {
    func testTodo() async throws {
        try await verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    func testTodoMessage() async throws {
        let example = Example("fatalError() // TODO: Implement")
        let violations = try await self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "TODOs should be resolved (Implement)")
    }

    func testFixMeMessage() async throws {
        let example = Example("fatalError() // FIXME: Implement")
        let violations = try await self.violations(example)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "FIXMEs should be resolved (Implement)")
    }

    private func violations(_ example: Example) async throws -> [StyleViolation] {
        let config = makeConfig(nil, TodoRule.description.identifier)!
        return try await SwiftLintFrameworkTests.violations(example, config: config)
    }
}
