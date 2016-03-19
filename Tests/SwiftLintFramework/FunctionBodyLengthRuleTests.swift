//
//  FunctionBodyLengthRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/01/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

private func funcWithBody(body: String) -> String {
    return "func abc() {\nvar x = 0\n\(body)}\n"
}

class FunctionBodyLengthRuleTests: XCTestCase {

    func testFunctionBodyLengths() {
        let longFunctionBody = funcWithBody(
            Repeat(count: 39, repeatedValue: "x = 0\n").joinWithSeparator("")
        )
        XCTAssertEqual(violations(longFunctionBody), [])

        let longerFunctionBody = funcWithBody(
            Repeat(count: 40, repeatedValue: "x = 0\n").joinWithSeparator("")
        )
        XCTAssertEqual(violations(longerFunctionBody), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])

        let longerFunctionBodyWithEmptyLines = funcWithBody(
            Repeat(count: 100, repeatedValue: "\n").joinWithSeparator("")
        )
        XCTAssertEqual(violations(longerFunctionBodyWithEmptyLines), [])
    }

    func testFunctionBodyLengthsWithComments() {
        let longFunctionBodyWithComments = funcWithBody(
            Repeat(count: 39, repeatedValue: "x = 0\n").joinWithSeparator("") +
            "// comment only line should be ignored.\n"
        )
        XCTAssertEqual(violations(longFunctionBodyWithComments), [])

        let longerFunctionBodyWithComments = funcWithBody(
            Repeat(count: 40, repeatedValue: "x = 0\n").joinWithSeparator("") +
            "// comment only line should be ignored.\n"
        )
        XCTAssertEqual(violations(longerFunctionBodyWithComments), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])
    }

    func testFunctionBodyLengthsWithMultilineComments() {
        let longFunctionBodyWithMultilineComments = funcWithBody(
            Repeat(count: 39, repeatedValue: "x = 0\n").joinWithSeparator("") +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(violations(longFunctionBodyWithMultilineComments), [])

        let longerFunctionBodyWithMultilineComments = funcWithBody(
            Repeat(count: 40, repeatedValue: "x = 0\n").joinWithSeparator("") +
            "/* multi line comment only line should be ignored.\n*/\n"
        )
        XCTAssertEqual(violations(longerFunctionBodyWithMultilineComments), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less excluding comments and " +
            "whitespace: currently spans 41 lines")])
    }
}
