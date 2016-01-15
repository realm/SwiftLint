//
//  FunctionBodyLengthRuleTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/01/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class FunctionBodyLengthRuleTests: XCTestCase {
    func testFunctionBodyLengths() {
        let longFunctionBody = "func abc() {\n" +
            "var x = 0\n" +
            Repeat(count: 39, repeatedValue: "x = 0\n").joinWithSeparator("") +
        "}\n"
        XCTAssertEqual(violations(longFunctionBody), [])

        let longerFunctionBody = "func abc() {\n" +
            "var x = 0\n" +
            Repeat(count: 40, repeatedValue: "x = 0\n").joinWithSeparator("") +
        "}\n"
        XCTAssertEqual(violations(longerFunctionBody), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less: currently spans 41 lines " +
            "(already ignoring comment and whitespace only ones)")])

        let longerFunctionBodyWithEmptyLines = "func abc() {" +
            Repeat(count: 100, repeatedValue: "\n").joinWithSeparator("") +
        "}\n"
        XCTAssertEqual(violations(longerFunctionBodyWithEmptyLines), [])
    }

    func testFunctionBodyLengthsWithComments() {
        let longFunctionBodyWithComments = "func abc() {\n" +
            "var x = 0\n" +
            Repeat(count: 39, repeatedValue: "x = 0\n").joinWithSeparator("") +
            "// comment only line should be ignored.\n" +
        "}\n"
        XCTAssertEqual(violations(longFunctionBodyWithComments), [])

        let longerFunctionBodyWithComments = "func abc() {\n" +
            "var x = 0\n" +
            Repeat(count: 40, repeatedValue: "x = 0\n").joinWithSeparator("") +
            "// comment only line should be ignored.\n" +
        "}\n"
        XCTAssertEqual(violations(longerFunctionBodyWithComments), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less: currently spans 41 lines " +
            "(already ignoring comment and whitespace only ones)")])
    }

    func testFunctionBodyLengthsWithMultilineComments() {
        let longFunctionBodyWithMultilineComments = "func abc() {\n" +
            "var x = 0\n" +
            Repeat(count: 39, repeatedValue: "x = 0\n").joinWithSeparator("") +
            "/* multi line comment only line should be ignored.\n*/\n" +
        "}\n"
        XCTAssertEqual(violations(longFunctionBodyWithMultilineComments), [])

        let longerFunctionBodyWithMultilineComments = "func abc() {\n" +
            "var x = 0\n" +
            Repeat(count: 40, repeatedValue: "x = 0\n").joinWithSeparator("") +
            "/* multi line comment only line should be ignored.\n*/\n" +
        "}\n"
        XCTAssertEqual(violations(longerFunctionBodyWithMultilineComments), [StyleViolation(
            ruleDescription: FunctionBodyLengthRule.description,
            location: Location(file: nil, line: 1, character: 1),
            reason: "Function body should span 40 lines or less: currently spans 41 lines " +
            "(already ignoring comment and whitespace only ones)")])
    }
}
