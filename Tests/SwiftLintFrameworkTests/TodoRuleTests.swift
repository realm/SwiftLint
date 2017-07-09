//
//  TodoRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 02/26/17.
//  Copyright © 2017 Realm. All rights reserved.
//

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
        XCTAssertEqual(violations.first!.reason, "TODOs should be avoided (Implement).")
    }

    func testFixMeMessage() {
        let string = "fatalError() // FIXME: Implement"
        let violations = self.violations(string)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first!.reason, "FIXMEs should be avoided (Implement).")
    }

    private func violations(_ string: String) -> [StyleViolation] {
        let config = makeConfig(nil, TodoRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
