//
//  FunctionBodyCommentsRuleTests.swift
//  SwiftLint
//
//  Created by Mikhail Yakushin on 02/28/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

private func funcWithBody(_ body: String, violates: Bool = false) -> String {
    let marker = violates ? "↓" : ""
    return "func \(marker)abc() {\nvar x = 0\n\(body)}\n"
}

private func violatingFuncWithBody(_ body: String) -> String {
    return funcWithBody(body, violates: true)
}

class FunctionBodyCommentsRuleTests: XCTestCase {

    func testFunctionBodyCommentsValid() {
        let longFunctionBody = funcWithBody(repeatElement("x = 0\n", count: 39).joined())
        XCTAssertEqual(violations(longFunctionBody), [])
    }

    func testFunctionBodyCommentsInLine() {
        let longFunctionBodyWithComments = violatingFuncWithBody(
                repeatElement("x = 0\n", count: 40).joined() +
                        "// in line comments are prohibited.\n"
        )
        XCTAssertNotEqual(violations(longFunctionBodyWithComments), [])
    }

    func testFunctionBodyCommentsMultiLine() {
        let longFunctionBodyWithMultilineComments = funcWithBody(
                repeatElement("x = 0\n", count: 40).joined() +
                        "/* multi line comments are prohibited.\n*/\n"
        )
        XCTAssertNotEqual(violations(longFunctionBodyWithMultilineComments), [])
    }

    private func violations(_ string: String) -> [StyleViolation] {
        let config = makeConfig(nil, FunctionBodyCommentsRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }

}
