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

func violations(string: String) -> [StyleViolation] {
    return Linter(file: File(contents: string)).styleViolations
}

class LinterTests: XCTestCase {

    // MARK: Integration Tests

    func testThisFile() {
        XCTAssertEqual(violations(File(path: __FILE__)!.contents), [])
    }

    // MARK: AST Violations

    func testTypeNames() {
        for kind in ["class", "struct", "enum"] {
            XCTAssertEqual(violations("\(kind) Abc {}\n"), [])

            XCTAssertEqual(violations("\(kind) Ab_ {}\n"), [StyleViolation(type: .NameFormat,
                location: Location(file: nil, line: 1),
                reason: "Type name should only contain alphanumeric characters: 'Ab_'")])

            XCTAssertEqual(violations("\(kind) abc {}\n"), [StyleViolation(type: .NameFormat,
                location: Location(file: nil, line: 1),
                reason: "Type name should start with an uppercase character: 'abc'")])

            XCTAssertEqual(violations("\(kind) Ab {}\n"), [StyleViolation(type: .NameFormat,
                location: Location(file: nil, line: 1),
                reason: "Type name should be between 3 and 40 characters in length: 'Ab'")])
            XCTAssertEqual(violations("\(kind) Abc {}\n"), [])

            let longName = join("", Array(count: 40, repeatedValue: "A"))
            XCTAssertEqual(violations("\(kind) \(longName) {}\n"), [])
            let longerName = longName + "A"
            XCTAssertEqual(violations("\(kind) \(longerName) {}\n"), [
                StyleViolation(type: .NameFormat,
                    location: Location(file: nil, line: 1),
                    reason: "Type name should be between 3 and 40 characters in length: " +
                    "'\(longerName)'")
                ])
        }

        // Test typealias
        // TODO: Uncomment this once rdar://18845613 is fixed.
//        XCTAssertEqual(violations("typealias Abc = Void\n"), [])
//        XCTAssertEqual(violations("typealias abc = Void\n"), [StyleViolation(type: .NameFormat,
//            location: Location(file: nil),
//            reason: "Type name should start with an uppercase character: 'abc'")])

        // Test enum element
        // TODO: Uncomment this once rdar://18845613 is fixed.
//        XCTAssertEqual(violations("enum Abc { case Def }\n"), [])
//        XCTAssertEqual(violations("enum Abc { case def }\n"), [StyleViolation(type: .NameFormat,
//            location: Location(file: nil),
//            reason: "Type name should start with an uppercase character: 'def'")])

        // Test nested type
        XCTAssertEqual(violations("class Abc {\n    class Def {}\n}\n"), [])
        XCTAssertEqual(violations("class Abc {\n    class def\n}\n"),
            [
                StyleViolation(type: .NameFormat,
                    location: Location(file: nil, line: 2),
                    reason: "Type name should start with an uppercase character: 'def'")
            ])

        // TODO: Support generic type names.
    }

    func testVariableNames() {
        // TODO: Variable names should contain between 3 and 20 characters.
    }

    func testClosureLengths() {
        // TODO: Closures should be 20 lines or less.
    }

    func testFunctionLengths() {
        // TODO: Functions should be 40 lines or less.
    }

    func testTypeLengths() {
        // TODO: Types should be 200 lines or less.
    }

    func testNesting() {
        // TODO: Types should be nested 3 levels deep or less.
        // TODO: Everything should be nested 5 levels deep or less.
    }

    func testColon() {
        // TODO: Colon should be adjacent to the declaration name, with a single space between
        //       itself and the type.
        //
        //       Good:
        //         - `let a: T`
        //       Bad:
        //         - `let a : T`
        //         - `let a :T`
        //         - `let a:  T`
    }

    func testControlStatements() {
        // TODO: if,for,while,do statements shouldn't wrap their conditionals in parentheses.
    }

    func testNumberOfFunctionsInAType() {
        // TODO: Types should contain 10 functions or less.
    }

    func testTrailingClosureSyntax() {
        // TODO: Trailing closure syntax should be used whenever possible.
    }

    func testTODOAndFIXME() {
        // TODO: Files should not contain any TODOs or FIXMEs.
    }

    func testNoForceUnwrapping() {
        // TODO: Force unwrapping should not be used.
    }

    func testNoImplicitlyUnwrappedOptionals() {
        // TODO: Implicitly unwrapped optionals should not be used.
    }

    func testPreferImplicitGettersOnReadOnly() {
        // TODO: Read-only properties and subscripts should avoid using the `get` keyword.
    }

    func testExplicitAccessControlKeywordsForTopLevelDeclarations() {
        // TODO: Top-level declarations should use explicit ACL keywords
        //       (`public`, `internal`, `private`).
    }

    func testAvoidSelfOutsideClosuresAndConflicts() {
        // TODO: Use of `self` should be limited to closures and scopes in which other
        //       declarations conflict.
    }

    func testUseWhitespaceAroundOperatorDefinitions() {
        // TODO: Use whitespace around operator definitions.
        //
        // Good: `func <|< <A>(lhs: A, rhs: A) -> A`
        // Bad:  `func <|<<A>(lhs: A, rhs: A) -> A`
    }

    // MARK: String Violations

    func testLineLengths() {
        let longLine = join("", Array(count: 100, repeatedValue: "/"))
        XCTAssertEqual(violations(longLine + "\n"), [])
        XCTAssertEqual(violations(longLine + "/\n"), [StyleViolation(type: .Length,
            location: Location(file: nil, line: 1),
            reason: "Line #1 should be 100 characters or less: currently 101 characters")])
    }

    func testTrailingNewlineAtEndOfFile() {
        XCTAssertEqual(violations("//\n"), [])
        XCTAssertEqual(violations(""), [StyleViolation(type: .TrailingNewline,
            location: Location(file: nil),
            reason: "File should have a single trailing newline: currently has 0")])
        XCTAssertEqual(violations("//\n\n"), [StyleViolation(type: .TrailingNewline,
            location: Location(file: nil),
            reason: "File should have a single trailing newline: currently has 2")])
    }

    func testFileLengths() {
        let manyLines = join("", Array(count: 400, repeatedValue: "//\n"))
        XCTAssertEqual(violations(manyLines), [])
        XCTAssertEqual(violations(manyLines + "//\n"), [StyleViolation(type: .Length,
            location: Location(file: nil),
            reason: "File should contain 400 lines or less: currently contains 401")])
    }

    func testFileShouldntStartWithWhitespace() {
        XCTAssertEqual(violations("//\n"), [])
        XCTAssertEqual(violations("\n"), [StyleViolation(type: .LeadingWhitespace,
            location: Location(file: nil, line: 1),
            reason: "File shouldn't start with whitespace: currently starts with 1 whitespace " +
            "characters")])
        XCTAssertEqual(violations(" //\n"), [StyleViolation(type: .LeadingWhitespace,
            location: Location(file: nil, line: 1),
            reason: "File shouldn't start with whitespace: currently starts with 1 whitespace " +
            "characters")])
    }

    func testLinesShouldntContainTrailingWhitespace() {
        XCTAssertEqual(violations("//\n"), [])
        XCTAssertEqual(violations("// \n"), [StyleViolation(type: .TrailingWhitespace,
            location: Location(file: nil, line: 1),
            reason: "Line #1 should have no trailing whitespace: current has 1 trailing " +
            "whitespace characters")])
    }

    func testForceCasting() {
        XCTAssertEqual(violations("NSNumber() as? Int\n"), [])
        XCTAssertEqual(violations("NSNumber() as! Int\n"),
            [StyleViolation(type: .ForceCast,
                location: Location(file: nil, line: 1),
                reason: "Force casts should be avoided")])
    }
}
