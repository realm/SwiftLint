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
    func testTypeNames() {
        for kind in ["class", "struct", "enum"] {
            XCTAssertEqual(violations("\(kind) Abc {}\n"), [])

            XCTAssertEqual(violations("\(kind) Ab_ {}\n"), [StyleViolation(
                ruleDescription: TypeNameRule.description,
                severity: .Error,
                location: Location(file: nil, line: 1, character: 1),
                reason: "Type name should only contain alphanumeric characters: 'Ab_'")])

            XCTAssertEqual(violations("\(kind) abc {}\n"), [StyleViolation(
                ruleDescription: TypeNameRule.description,
                severity: .Error,
                location: Location(file: nil, line: 1, character: 1),
                reason: "Type name should start with an uppercase character: 'abc'")])

            XCTAssertEqual(violations("\(kind) Ab {}\n"), [StyleViolation(
                ruleDescription: TypeNameRule.description,
                location: Location(file: nil, line: 1, character: 1),
                reason: "Type name should be between 3 and 40 characters in length: 'Ab'")])

            let longName = Repeat(count: 40, repeatedValue: "A").joinWithSeparator("")
            XCTAssertEqual(violations("\(kind) \(longName) {}\n"), [])
            let longerName = longName + "A"
            XCTAssertEqual(violations("\(kind) \(longerName) {}\n"), [
                StyleViolation(
                    ruleDescription: TypeNameRule.description,
                    location: Location(file: nil, line: 1, character: 1),
                    reason: "Type name should be between 3 and 40 characters in length: " +
                    "'\(longerName)'")
                ])
        }
    }

    func testNestedTypeNames() {
        XCTAssertEqual(violations("class Abc {\n    class Def {}\n}\n"), [])
        XCTAssertEqual(violations("class Abc {\n    class def\n}\n"),
            [
                StyleViolation(
                    ruleDescription: TypeNameRule.description,
                    severity: .Error,
                    location: Location(file: nil, line: 2, character: 5),
                    reason: "Type name should start with an uppercase character: 'def'")
            ]
        )
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
                        ruleDescription: VariableNameMaxLengthRule.description,
                        severity: .Warning,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should be 40 characters or less: currently " +
                        "41 characters")
                    ])

                let longestName = Repeat(count: 60, repeatedValue: "d").joinWithSeparator("")
                    + "d"
                XCTAssertEqual(violations("\(kind) Abc { \(varType) \(longestName): Void }\n"), [
                    StyleViolation(
                        ruleDescription: VariableNameMaxLengthRule.description,
                        severity: .Error,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should be 60 characters or less: currently " +
                        "61 characters")
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
                        ruleDescription: VariableNameMinLengthRule.description,
                        severity: .Error,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should be 2 characters or more: currently " +
                        "1 characters")
                    ])

                XCTAssertEqual(violations("\(kind) Abc { \(varType) de: Void }\n"), [
                    StyleViolation(
                        ruleDescription: VariableNameMinLengthRule.description,
                        severity: .Warning,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        reason: "Variable name should be 3 characters or more: currently " +
                        "2 characters")
                    ])
            }
        }
    }

    func testTypeBodyLengths() {
        for kind in ["class", "struct", "enum"] {
            let longTypeBody = "\(kind) Abc {" +
                Repeat(count: 200, repeatedValue: "\n").joinWithSeparator("") +
                "}\n"
            XCTAssertEqual(violations(longTypeBody), [])
            let longerTypeBody = "\(kind) Abc {" +
                Repeat(count: 201, repeatedValue: "\n").joinWithSeparator("") +
                "}\n"
            XCTAssertEqual(violations(longerTypeBody), [StyleViolation(
                ruleDescription: TypeBodyLengthRule.description,
                location: Location(file: nil, line: 1, character: 1),
                reason: "Type body should span 200 lines or less: currently spans 201 lines")])
        }
    }

    func testTypeNamesVerifyRule() {
        verifyRule(TypeNameRule.description)
    }

    func testVariableNamesVerifyRule() {
        verifyRule(VariableNameRule.description)
    }

    func testVariableNameMaxLengthsVerifyRule() {
        verifyRule(VariableNameMaxLengthRule.description)
    }

    func testVariableNameMinLengthsVerifyRule() {
        verifyRule(VariableNameMinLengthRule.description)
    }

    func testNesting() {
        verifyRule(NestingRule.description)
    }

    func testControlStatements() {
        verifyRule(ControlStatementRule.description)
    }
}
