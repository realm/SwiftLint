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
            ("/", 101, .VeryLow),
            (Repeat(count: 21, repeatedValue: "/").joinWithSeparator(""), 121, .Low),
            (Repeat(count: 51, repeatedValue: "/").joinWithSeparator(""), 151, .Medium),
            (Repeat(count: 101, repeatedValue: "/").joinWithSeparator(""), 201, .High),
            (Repeat(count: 151, repeatedValue: "/").joinWithSeparator(""), 251, .VeryHigh)
        ]
        for testCase in testCases {
            XCTAssertEqual(violations(testCase.0 + longLine), [StyleViolation(type: .Length,
                location: Location(file: nil, line: 1),
                severity: testCase.2,
                reason: "Line should be 100 characters or less: " +
                "currently \(testCase.1) characters")])
        }
    }

    func testTrailingNewlineAtEndOfFile() {
        XCTAssertEqual(violations("//\n"), [])
        XCTAssertEqual(violations(""), [StyleViolation(type: .TrailingNewline,
            location: Location(file: nil, line: 1),
            severity: .Medium,
            reason: "File should have a single trailing newline")])
        XCTAssertEqual(violations("//\n\n"), [StyleViolation(type: .TrailingNewline,
            location: Location(file: nil, line: 3),
            severity: .Medium,
            reason: "File should have a single trailing newline")])
    }

    func testFileLengths() {
        XCTAssertEqual(
            violations(Repeat(count: 400, repeatedValue: "//\n").joinWithSeparator("")),
            []
        )
        let testCases: [(String, Int, ViolationSeverity)] = [
            (Repeat(count: 401, repeatedValue: "//\n").joinWithSeparator(""), 401, .VeryLow),
            (Repeat(count: 501, repeatedValue: "//\n").joinWithSeparator(""), 501, .Low),
            (Repeat(count: 751, repeatedValue: "//\n").joinWithSeparator(""), 751, .Medium),
            (Repeat(count: 1001, repeatedValue: "//\n").joinWithSeparator(""), 1001, .High),
            (Repeat(count: 2001, repeatedValue: "//\n").joinWithSeparator(""), 2001, .VeryHigh)
        ]
        for testCase in testCases {
            XCTAssertEqual(violations(testCase.0), [StyleViolation(type: .Length,
                location: Location(file: nil, line: testCase.1),
                severity: testCase.2,
                reason: "File should contain 400 lines or less: currently contains \(testCase.1)")])
        }
    }

    func testFileShouldntStartWithWhitespace() {
        verifyRule(LeadingWhitespaceRule().example,
            type: .LeadingWhitespace,
            commentDoesntViolate: false)
    }

    func testLinesShouldntContainTrailingWhitespace() {
        verifyRule(TrailingWhitespaceRule().example,
            type: .TrailingWhitespace,
            commentDoesntViolate: false)
    }

    func testLinesShouldContainReturnArrowWhitespace() {
        verifyRule(ReturnArrowWhitespaceRule().example,
            type: .ReturnArrowWhitespace)
    }

    func testForceCasting() {
        verifyRule(ForceCastRule().example, type: .ForceCast)
    }

    func testOperatorFunctionWhitespace() {
        verifyRule(OperatorFunctionWhitespaceRule().example, type: .OperatorFunctionWhitespace)
    }

    func testTodoOrFIXME() {
        verifyRule(TodoRule().example, type: .TODO)
    }

    func testColon() {
        verifyRule(ColonRule().example, type: .Colon)
    }
}
