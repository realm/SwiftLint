//
//  ASTRuleTests.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class ASTRuleTests: XCTestCase {
    func testTypeName() {
        verifyRule(TypeNameRule.description)
    }

    func testVariableNames() {
        for kind in ["class", "struct"] {
            for varType in ["var", "let"] {
                let characterOffset = 8 + kind.characters.count
                XCTAssertEqual(violations("\(kind) Abc { \(varType) def: Void }\n"), [])
                XCTAssertEqual(violations("\(kind) Abc { \(varType) de_: Void }\n"), [
                    StyleViolation(
                        ruleDescription: VariableNameRule.description,
                        severity: .Error,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should only contain alphanumeric characters: 'de_'")
                    ])
                XCTAssertEqual(violations("\(kind) Abc { \(varType) Def: Void }\n"), [
                    StyleViolation(
                        ruleDescription: VariableNameRule.description,
                        severity: .Error,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should start with a lowercase character: 'Def'")
                    ])
            }
        }
    }

    func testVariableNameMaxLengths() {
        for kind in ["class", "struct"] {
            for varType in ["var", "let"] {
                let characterOffset = 8 + kind.characters.count
                let longName = Repeat(count: 40, repeatedValue: "d").joinWithSeparator("")
                XCTAssertEqual(violations("\(kind) Abc { \(varType) \(longName): Void }\n"), [])
                let longerName = longName + "d"
                XCTAssertEqual(violations("\(kind) Abc { \(varType) \(longerName): Void }\n"), [
                    StyleViolation(
                        ruleDescription: VariableNameRule.description,
                        severity: .Warning,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should be between 3 and " +
                                "40 characters long: '\(longerName)'")
                    ])

                let longestName = Repeat(count: 60, repeatedValue: "d").joinWithSeparator("")
                    + "d"
                XCTAssertEqual(violations("\(kind) Abc { \(varType) \(longestName): Void }\n"), [
                    StyleViolation(
                        ruleDescription: VariableNameRule.description,
                        severity: .Error,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should be between 3 and " +
                                "40 characters long: '\(longestName)'")
                    ])
            }
        }
    }

    func testVariableNameMinLengths() {
        for kind in ["class", "struct"] {
            for varType in ["var", "let"] {
                let characterOffset = 8 + kind.characters.count
                XCTAssertEqual(violations("\(kind) Abc { \(varType) def: Void }\n"), [])
                XCTAssertEqual(violations("\(kind) Abc { \(varType) d: Void }\n"), [
                    StyleViolation(
                        ruleDescription: VariableNameRule.description,
                        severity: .Error,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should be between 3 and " +
                                "40 characters long: 'd'")
                    ])

                XCTAssertEqual(violations("\(kind) Abc { \(varType) de: Void }\n"), [
                    StyleViolation(
                        ruleDescription: VariableNameRule.description,
                        severity: .Warning,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should be between 3 and " +
                                "40 characters long: 'de'")
                    ])
            }
        }
    }

    func testTypeBodyLengths() {
        func typeWithKind(kind: String, body: String) -> String {
            return "\(kind) Abc {\n\(body)}\n"
        }
        for kind in ["class", "struct", "enum"] {
            let longTypeBody = typeWithKind(kind, body:
                Repeat(count: 199, repeatedValue: "let abc = 0\n").joinWithSeparator(""))
            XCTAssertEqual(violations(longTypeBody), [])
            let longerTypeBody = typeWithKind(kind, body:
                Repeat(count: 201, repeatedValue: "let abc = 0\n").joinWithSeparator(""))
            XCTAssertEqual(violations(longerTypeBody), [StyleViolation(
                ruleDescription: TypeBodyLengthRule.description,
                location: Location(file: nil, line: 1, character: 1),
                reason: "Type body should span 200 lines or less excluding comments and " +
                "whitespace: currently spans 201 lines")])

            let longerTypeBodyWithWhitespaceLines = typeWithKind(kind, body:
                Repeat(count: 201, repeatedValue: "\n").joinWithSeparator(""))
            XCTAssertEqual(violations(longerTypeBodyWithWhitespaceLines), [])

            let longerTypeBodyWithCommentedLines = typeWithKind(kind, body:
                Repeat(count: 201, repeatedValue: "// this is a comment\n").joinWithSeparator(""))
            XCTAssertEqual(violations(longerTypeBodyWithCommentedLines), [])

            let longerTypeBodyWithMultilineComments = typeWithKind(kind, body:
                Repeat(count: 199, repeatedValue: "let abc = 0\n").joinWithSeparator("") +
                "/* this is\n" +
                "a multiline comment\n*/")
            XCTAssertEqual(violations(longerTypeBodyWithMultilineComments), [])
        }
    }

    func testTypeNamesVerifyRule() {
        verifyRule(TypeNameRule.description)
    }

    func testVariableNamesVerifyRule() {
        verifyRule(VariableNameRule.description)
    }

    func testNesting() {
        verifyRule(NestingRule.description)
    }

    func testControlStatements() {
        verifyRule(ControlStatementRule.description)
    }

    func testCyclomaticComplexity() {
        verifyRule(CyclomaticComplexityRule.description)
    }
}
