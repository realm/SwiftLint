//
//  StringRuleTests.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class StringRuleTests: XCTestCase {
    func testLineLengths() {
        let longLine = Repeat(count: 100, repeatedValue: "/").joinWithSeparator("") + "\n"
        XCTAssertEqual(violations(longLine), [])
        let testCases: [(String, Int, ViolationSeverity)] = [
            ("/", 101, .Warning),
            (Repeat(count: 101, repeatedValue: "/").joinWithSeparator(""), 201, .Error)
        ]
        for testCase in testCases {
            XCTAssertEqual(violations(testCase.0 + longLine), [StyleViolation(
                ruleDescription: LineLengthRule.description,
                severity: testCase.2,
                location: Location(file: nil, line: 1),
                reason: "Line should be 100 characters or less: currently \(testCase.1) " +
                        "characters")])
        }
    }

    func testFileLengths() {
        XCTAssertEqual(
            violations(Repeat(count: 400, repeatedValue: "//\n").joinWithSeparator("")),
            []
        )
        let testCases: [(String, Int, ViolationSeverity)] = [
            (Repeat(count: 401, repeatedValue: "//\n").joinWithSeparator(""), 401, .Warning),
            (Repeat(count: 1001, repeatedValue: "//\n").joinWithSeparator(""), 1001, .Error)
        ]
        for testCase in testCases {
            XCTAssertEqual(violations(testCase.0), [StyleViolation(
                ruleDescription: FileLengthRule.description,
                severity: testCase.2,
                location: Location(file: nil, line: testCase.1),
                reason: "File should contain 400 lines or less: currently contains \(testCase.1)")])
        }
    }

    func testFileShouldntStartWithWhitespace() {
        verifyRule(LeadingWhitespaceRule.description)
    }

    func testLinesShouldntContainTrailingWhitespace() {
        verifyRule(TrailingWhitespaceRule.description, commentDoesntViolate: false)
    }

    func testLinesShouldContainReturnArrowWhitespace() {
        verifyRule(ReturnArrowWhitespaceRule.description)
    }

    func testForceCasting() {
        verifyRule(ForceCastRule.description)
    }

    func testForceTry() {
        verifyRule(ForceTryRule.description)
    }

    func testOperatorFunctionWhitespace() {
        verifyRule(OperatorFunctionWhitespaceRule.description)
    }

    func testTodoOrFIXME() {
        verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    func testColon() {
        verifyRule(ColonRule.description)
    }

    func testOpeningBrace() {
        verifyRule(OpeningBraceRule.description)
	}

    func testClosingBrace() {
        verifyRule(ClosingBraceRule.description)
    }

    func testComma() {
        verifyRule(CommaRule.description)
    }

    func testStatementPosition() {
        verifyRule(StatementPositionRule.description)
    }

    func testTrailingNewline() {
        verifyRule(TrailingNewlineRule.description, commentDoesntViolate: false,
                   stringDoesntViolate: false)
    }

    func testValidDocs() {
        verifyRule(ValidDocsRule.description)
    }

    func testMissingDocs() {
        verifyRule(MissingDocsRule.description)
    }

    func testTrailingSemicolon() {
        verifyRule(TrailingSemicolonRule.description)
    }

    func testLegacyConstructor() {
        verifyRule(LegacyConstructorRule.description)
    }

    func testConditionalBindingCascade() {
        verifyRule(ConditionalBindingCascadeRule.description)
    }

    func testEmptyCount() {
        verifyRule(EmptyCountRule.description)
    }

    func testLegacyConstant() {
        verifyRule(LegacyConstantRule.description)
    }
}
