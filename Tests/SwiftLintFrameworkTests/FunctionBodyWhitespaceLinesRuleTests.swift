//
//  FunctionBodyLengthRule.swift
//  SwiftLint
//
//  Created by Mikhail Yakushin on 5/24/18.
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

class FunctionBodyWhitespaceLinesRuleTests: XCTestCase {

    func testFunctionBodyWhitespaceCommentLinesWithComment() {
        let longFunctionBodyWithComments = violatingFuncWithBody(
                repeatElement("x = 0 \n // comment is a violation \n", count: 1).joined()
        )
        XCTAssertNotEqual(violations(longFunctionBodyWithComments), [])
    }

    func testFunctionBodyWhitespaceCommentLinesWithMultiLineComment() {
        let longFunctionBodyWithComments = violatingFuncWithBody(
                repeatElement("x = 0 \n /* multi line comment is a violation \n */ \n", count: 1).joined()
        )
        XCTAssertNotEqual(violations(longFunctionBodyWithComments), [])
    }

    func testFunctionBodyWhitespaceCommentLinesValid() {
        let longFunctionBodyWithComments = funcWithBody(
                repeatElement("x = 0 \n x = 0", count: 1).joined()
        )
        XCTAssertEqual(violations(longFunctionBodyWithComments), [])
    }

    private func violations(_ string: String) -> [StyleViolation] {
        let config = makeConfig(nil, FunctionBodyWhitespaceCommentRule.description.identifier)!
        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
