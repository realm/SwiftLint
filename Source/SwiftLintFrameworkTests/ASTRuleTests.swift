//
//  ASTRuleTests.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SwiftLintFramework
import SourceKittenFramework
import XCTest

class ASTRuleTests: XCTestCase {
    func testTypeNames() {
        for kind in ["class", "struct", "enum"] {
            XCTAssertEqual(violations("\(kind) Abc {}\n"), [])

            XCTAssertEqual(violations("\(kind) Ab_ {}\n"), [StyleViolation(type: .NameFormat,
                location: Location(file: nil, line: 1, character: 1),
                severity: .Error,
                reason: "Type name should only contain alphanumeric characters: 'Ab_'")])

            XCTAssertEqual(violations("\(kind) abc {}\n"), [StyleViolation(type: .NameFormat,
                location: Location(file: nil, line: 1, character: 1),
                severity: .Error,
                reason: "Type name should start with an uppercase character: 'abc'")])

            XCTAssertEqual(violations("\(kind) Ab {}\n"), [StyleViolation(type: .NameFormat,
                location: Location(file: nil, line: 1, character: 1),
                severity: .Warning,
                reason: "Type name should be between 3 and 40 characters in length: 'Ab'")])

            let longName = Repeat(count: 40, repeatedValue: "A").joinWithSeparator("")
            XCTAssertEqual(violations("\(kind) \(longName) {}\n"), [])
            let longerName = longName + "A"
            XCTAssertEqual(violations("\(kind) \(longerName) {}\n"), [
                StyleViolation(type: .NameFormat,
                    location: Location(file: nil, line: 1, character: 1),
                    severity: .Warning,
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
                    location: Location(file: nil, line: 2, character: 5),
                    severity: .Error,
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
                    StyleViolation(type: .NameFormat,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        severity: .Error,
                        reason: "Variable name should only contain alphanumeric characters: 'de_'")
                    ])

                XCTAssertEqual(violations("\(kind) Abc { \(varType) Def: Void }\n"), [
                    StyleViolation(type: .NameFormat,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        severity: .Error,
                        reason: "Variable name should start with a lowercase character: 'Def'")
                    ])

                XCTAssertEqual(violations("\(kind) Abc { \(varType) de: Void }\n"), [
                    StyleViolation(type: .NameFormat,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        severity: .Warning,
                        reason: "Variable name should be between 3 and 40 characters in length: " +
                        "'de'")
                    ])

                let longName = Repeat(count: 40, repeatedValue: "d").joinWithSeparator("")
                XCTAssertEqual(violations("\(kind) Abc { \(varType) \(longName): Void }\n"), [])
                let longerName = longName + "d"
                XCTAssertEqual(violations("\(kind) Abc { \(varType) \(longerName): Void }\n"), [
                    StyleViolation(type: .NameFormat,
                        location: Location(file: nil, line: 1, character: characterOffset),
                        severity: .Warning,
                        reason: "Variable name should be between 3 and 40 characters in length: " +
                        "'\(longerName)'")
                    ])
            }
        }
    }

    func testFunctionBodyLengths() {
        let longFunctionBody = "func abc() {" +
            Repeat(count: 40, repeatedValue: "\n").joinWithSeparator("") +
            "}\n"
        XCTAssertEqual(violations(longFunctionBody), [])
        let longerFunctionBody = "func abc() {" +
            Repeat(count: 41, repeatedValue: "\n").joinWithSeparator("") +
            "}\n"
        XCTAssertEqual(violations(longerFunctionBody), [StyleViolation(type: .Length,
            location: Location(file: nil, line: 1, character: 1),
            severity: .Warning,
            reason: "Function body should be span 40 lines or less: currently spans 41 lines")])
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
            XCTAssertEqual(violations(longerTypeBody), [StyleViolation(type: .Length,
                location: Location(file: nil, line: 1, character: 1),
                severity: .Warning,
                reason: "Type body should be span 200 lines or less: currently spans 201 lines")])
        }
    }

    func testTypeNamesVerifyRule() {
        verifyRule(TypeNameRule(), type: .NameFormat)
    }

    func testParameterizedTypeNameRule() {
        let rule = TypeNameRule(parameters: [
            RuleParameter(severity: .Warning, value: 2),
            RuleParameter(severity: .Warning, value: 4)
            ])

        let tooShortViolations = rule.validateFile(File(contents: "struct A{}"))
        XCTAssert(tooShortViolations.count == 1, "Should have single violation")
        if let violation = tooShortViolations.first {
            XCTAssert(violation.type == .NameFormat, "Unexpected type")
            XCTAssert(violation.severity == .Warning, "Unexpected severity")
            XCTAssert(violation.location == Location(file: nil, line: 1, character: 1),
                "Unexpected location")
        }

        let tooLongViolations = rule.validateFile(File(contents: "struct Abcde{}"))
        XCTAssert(tooLongViolations.count == 1, "Should have single violation")
        if let violation = tooLongViolations.first {
            XCTAssert(violation.type == .NameFormat, "Unexpected type")
            XCTAssert(violation.severity == .Warning, "Unexpected severity")
            XCTAssert(violation.location == Location(file: nil, line: 1, character: 1),
                "Unexpected location")
        }
    }

    func testVariableNamesVerifyRule() {
        verifyRule(VariableNameRule(), type: .NameFormat)
    }

    func testNesting() {
        verifyRule(NestingRule(), type: .Nesting, commentDoesntViolate: false)
    }

    func testControlStatements() {
        verifyRule(ControlStatementRule(), type: .ControlStatement)
    }
}
