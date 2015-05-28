//
//  LinterTests.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SwiftLintFramework
import SourceKittenFramework
import XCTest

// MARK: Test Helpers

func violations(string: String) -> [StyleViolation] {
    return Linter(file: File(contents: string)).styleViolations
}

extension XCTestCase {
    func verifyRule(rule: RuleExample,
        type: StyleViolationType,
        commentDoesntViolate: Bool = true) {
            XCTAssertEqual(rule.nonTriggeringExamples.flatMap({violations($0)}), [])
            XCTAssertEqual(rule.triggeringExamples.flatMap({violations($0).map({$0.type})}),
                Array(count: rule.triggeringExamples.count, repeatedValue: type))

            if commentDoesntViolate {
                XCTAssertEqual(rule.triggeringExamples.flatMap({violations("// " + $0)}), [])
            }
    }
}

// MARK: Tests

class LinterTests: XCTestCase {

    // MARK: AST Violations

    func testTypeNames() {
        for kind in ["class", "struct", "enum"] {
            XCTAssertEqual(violations("\(kind) Abc {}\n"), [])

            XCTAssertEqual(violations("\(kind) Ab_ {}\n"), [StyleViolation(type: .NameFormat,
                location: Location(file: nil, line: 1),
                severity: .High,
                reason: "Type name should only contain alphanumeric characters: 'Ab_'")])

            XCTAssertEqual(violations("\(kind) abc {}\n"), [StyleViolation(type: .NameFormat,
                location: Location(file: nil, line: 1),
                severity: .High,
                reason: "Type name should start with an uppercase character: 'abc'")])

            XCTAssertEqual(violations("\(kind) Ab {}\n"), [StyleViolation(type: .NameFormat,
                location: Location(file: nil, line: 1),
                severity: .Medium,
                reason: "Type name should be between 3 and 40 characters in length: 'Ab'")])

            let longName = join("", Array(count: 40, repeatedValue: "A"))
            XCTAssertEqual(violations("\(kind) \(longName) {}\n"), [])
            let longerName = longName + "A"
            XCTAssertEqual(violations("\(kind) \(longerName) {}\n"), [
                StyleViolation(type: .NameFormat,
                    location: Location(file: nil, line: 1),
                    severity: .Medium,
                    reason: "Type name should be between 3 and 40 characters in length: " +
                    "'\(longerName)'")
                ])
        }
    }

    func testNestedTypeNames() {
        XCTAssertEqual(violations("class Abc {\n    class Def {}\n}\n"), [])
        XCTAssertEqual(violations("class Abc {\n    class def\n}\n"),
            [
                StyleViolation(type: .NameFormat,
                    location: Location(file: nil, line: 2),
                    severity: .High,
                    reason: "Type name should start with an uppercase character: 'def'")
            ]
        )
    }

    func testVariableNames() {
        for kind in ["class", "struct"] {
            for varType in ["var", "let"] {
                XCTAssertEqual(violations("\(kind) Abc { \(varType) def: Void }\n"), [])

                XCTAssertEqual(violations("\(kind) Abc { \(varType) de_: Void }\n"), [
                    StyleViolation(type: .NameFormat,
                        location: Location(file: nil, line: 1),
                        severity: .High,
                        reason: "Variable name should only contain alphanumeric characters: 'de_'")
                    ])

                XCTAssertEqual(violations("\(kind) Abc { \(varType) Def: Void }\n"), [
                    StyleViolation(type: .NameFormat,
                        location: Location(file: nil, line: 1),
                        severity: .High,
                        reason: "Variable name should start with a lowercase character: 'Def'")
                    ])

                XCTAssertEqual(violations("\(kind) Abc { \(varType) de: Void }\n"), [
                    StyleViolation(type: .NameFormat,
                        location: Location(file: nil, line: 1),
                        severity: .Medium,
                        reason: "Variable name should be between 3 and 40 characters in length: " +
                        "'de'")
                    ])

                let longName = join("", Array(count: 40, repeatedValue: "d"))
                XCTAssertEqual(violations("\(kind) Abc { \(varType) \(longName): Void }\n"), [])
                let longerName = longName + "d"
                XCTAssertEqual(violations("\(kind) Abc { \(varType) \(longerName): Void }\n"), [
                    StyleViolation(type: .NameFormat,
                        location: Location(file: nil, line: 1),
                        severity: .Medium,
                        reason: "Variable name should be between 3 and 40 characters in length: " +
                        "'\(longerName)'")
                    ])
            }
        }
    }

    func testFunctionBodyLengths() {
        let longFunctionBody = "func abc() {" +
            join("", Array(count: 40, repeatedValue: "\n")) +
            "}\n"
        XCTAssertEqual(violations(longFunctionBody), [])
        let longerFunctionBody = "func abc() {" +
            join("", Array(count: 41, repeatedValue: "\n")) +
            "}\n"
        XCTAssertEqual(violations(longerFunctionBody), [StyleViolation(type: .Length,
            location: Location(file: nil, line: 1),
            severity: .VeryLow,
            reason: "Function body should be span 40 lines or less: currently spans 41 lines")])
    }

    func testTypeBodyLengths() {
        for kind in ["class", "struct", "enum"] {
            let longTypeBody = "\(kind) Abc {" +
                join("", Array(count: 200, repeatedValue: "\n")) +
                "}\n"
            XCTAssertEqual(violations(longTypeBody), [])
            let longerTypeBody = "\(kind) Abc {" +
                join("", Array(count: 201, repeatedValue: "\n")) +
                "}\n"
            XCTAssertEqual(violations(longerTypeBody), [StyleViolation(type: .Length,
                location: Location(file: nil, line: 1),
                severity: .VeryLow,
                reason: "Type body should be span 200 lines or less: currently spans 201 lines")])
        }
    }

    func testNesting() {
        verifyRule(NestingRule().example, type: .Nesting, commentDoesntViolate: false)
    }

    func testControlStatements() {
        verifyRule(ControlStatementRule().example, type: .ControlStatement)
    }

    // MARK: String Violations

    func testLineLengths() {
        let longLine = join("", Array(count: 100, repeatedValue: "/")) + "\n"
        XCTAssertEqual(violations(longLine), [])
        let testCases: [(String, Int, ViolationSeverity)] = [
            ("/", 101, .VeryLow),
            (join("", Array(count: 21, repeatedValue: "/")), 121, .Low),
            (join("", Array(count: 51, repeatedValue: "/")), 151, .Medium),
            (join("", Array(count: 101, repeatedValue: "/")), 201, .High),
            (join("", Array(count: 151, repeatedValue: "/")), 251, .VeryHigh)
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
            reason: "File should have a single trailing newline: currently has 0")])
        XCTAssertEqual(violations("//\n\n"), [StyleViolation(type: .TrailingNewline,
            location: Location(file: nil, line: 3),
            severity: .Medium,
            reason: "File should have a single trailing newline: currently has 2")])
    }

    func testFileLengths() {
        XCTAssertEqual(violations(join("", Array(count: 400, repeatedValue: "//\n"))), [])
        let testCases: [(String, Int, ViolationSeverity)] = [
            (join("", Array(count: 401, repeatedValue: "//\n")), 401, .VeryLow),
            (join("", Array(count: 501, repeatedValue: "//\n")), 501, .Low),
            (join("", Array(count: 751, repeatedValue: "//\n")), 751, .Medium),
            (join("", Array(count: 1001, repeatedValue: "//\n")), 1001, .High),
            (join("", Array(count: 2001, repeatedValue: "//\n")), 2001, .VeryHigh)
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

    func testForceCasting() {
        verifyRule(ForceCastRule().example, type: .ForceCast)
    }

    func testTodoOrFIXME() {
        verifyRule(TodoRule().example, type: .TODO)
    }

    func testColon() {
        verifyRule(ColonRule().example, type: .Colon)
    }
}
