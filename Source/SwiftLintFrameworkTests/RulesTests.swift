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
    func testClosingBraceRule() {
        verifyRule(ClosingBraceRule.description)
    }

    func testColonRule() {
        verifyRule(ColonRule.description)
    }

    func testCommaRule() {
        verifyRule(CommaRule.description)
    }

    func testConditionalBindingCascadeRule() {
        verifyRule(ConditionalBindingCascadeRule.description)
    }

    func testControlStatementRule() {
        verifyRule(ControlStatementRule.description)
    }

    func testCyclomaticComplexityRule() {
        verifyRule(CyclomaticComplexityRule.description)
    }

    func testEmptyCountRule() {
        verifyRule(EmptyCountRule.description)
    }

    func testFileLengthRule() {
        verifyRule(FileLengthRule.description, commentDoesntViolate: false)
    }

    func testForceCastRule() {
        verifyRule(ForceCastRule.description)
    }

    func testForceTryRule() {
        verifyRule(ForceTryRule.description)
    }

    func testFunctionBodyLengthRule() {
        verifyRule(FunctionBodyLengthRule.description)
    }

    func testLeadingWhitespaceRule() {
        verifyRule(LeadingWhitespaceRule.description)
    }

    func testLegacyConstantRule() {
        verifyRule(LegacyConstantRule.description)
    }

    func testLegacyConstructorRule() {
        verifyRule(LegacyConstructorRule.description)
    }

    func testLineLengthRule() {
        verifyRule(LineLengthRule.description, commentDoesntViolate: false,
            stringDoesntViolate: false)
    }

    func testMissingDocsRule() {
        verifyRule(MissingDocsRule.description)
    }

    func testNestingRule() {
        verifyRule(NestingRule.description)
    }

    func testOpeningBraceRule() {
        verifyRule(OpeningBraceRule.description)
    }

    func testOperatorFunctionWhitespaceRule() {
        verifyRule(OperatorFunctionWhitespaceRule.description)
    }

    func testReturnArrowWhitespaceRule() {
        verifyRule(ReturnArrowWhitespaceRule.description)
    }

    func testStatementPositionRule() {
        verifyRule(StatementPositionRule.description)
    }

    func testTodoRule() {
        verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    func testTrailingNewlineRule() {
        verifyRule(TrailingNewlineRule.description, commentDoesntViolate: false,
            stringDoesntViolate: false)
    }

    func testTrailingSemicolonRule() {
        verifyRule(TrailingSemicolonRule.description)
    }

    func testTrailingWhitespaceRule() {
        verifyRule(TrailingWhitespaceRule.description, commentDoesntViolate: false)
    }

    func testTypeBodyLengthRule() {
        verifyRule(TypeBodyLengthRule.description)
    }

    func testTypeNameRule() {
        verifyRule(TypeNameRule.description)
    }

    func testValidDocsRule() {
        verifyRule(ValidDocsRule.description)
    }

    func testVariableNameRule() {
        verifyRule(VariableNameRule.description)
    }
}
