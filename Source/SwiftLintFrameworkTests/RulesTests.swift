//
//  RulesTests.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

class RulesTests: XCTestCase {
    func testLineLength() {
        verifyRule(LineLengthRule.description, commentDoesntViolate: false,
            stringDoesntViolate: false)
    }

    func testFileLength() {
        verifyRule(FileLengthRule.description, commentDoesntViolate: false)
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
