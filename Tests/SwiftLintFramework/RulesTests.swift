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

    func testClosingBrace() {
        verifyRule(ClosingBraceRule.description)
    }

    func testColon() {
        verifyRule(ColonRule.description)
    }

    func testComma() {
        verifyRule(CommaRule.description)
    }

    func testConditionalBindingCascade() {
        verifyRule(ConditionalBindingCascadeRule.description)
    }

    func testControlStatement() {
        verifyRule(ControlStatementRule.description)
    }

    func testCyclomaticComplexity() {
        verifyRule(CyclomaticComplexityRule.description)
    }

    func testEmptyCount() {
        verifyRule(EmptyCountRule.description)
    }

    func testFileLength() {
        verifyRule(FileLengthRule.description, commentDoesntViolate: false)
    }

    func testForceCast() {
        verifyRule(ForceCastRule.description)
    }

    func testForceTry() {
        verifyRule(ForceTryRule.description)
    }

    func testForceUnwrapping() {
        verifyRule(ForceUnwrappingRule.description)
    }

    func testFunctionBodyLength() {
        verifyRule(FunctionBodyLengthRule.description)
    }

    func testFunctionParameterCountRule() {
        verifyRule(FunctionParameterCountRule.description)
    }

    func testLeadingWhitespace() {
        verifyRule(LeadingWhitespaceRule.description)
    }

    func testLegacyCGGeometryFunctions() {
        verifyRule(LegacyCGGeometryFunctionsRule.description)
    }

    func testLegacyConstant() {
        verifyRule(LegacyConstantRule.description)
    }

    func testLegacyConstructor() {
        verifyRule(LegacyConstructorRule.description)
    }

    func testLineLength() {
        verifyRule(LineLengthRule.description, commentDoesntViolate: false,
            stringDoesntViolate: false)
    }

    func testMissingDocs() {
        verifyRule(MissingDocsRule.description)
    }

    func testNesting() {
        verifyRule(NestingRule.description)
    }

    func testOpeningBrace() {
        verifyRule(OpeningBraceRule.description)
    }

    func testOperatorFunctionWhitespace() {
        verifyRule(OperatorFunctionWhitespaceRule.description)
    }

    func testReturnArrowWhitespace() {
        verifyRule(ReturnArrowWhitespaceRule.description)
    }

    func testStatementPosition() {
        verifyRule(StatementPositionRule.description)
    }

    func testTodo() {
        verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    func testTrailingNewline() {
        verifyRule(TrailingNewlineRule.description, commentDoesntViolate: false,
            stringDoesntViolate: false)
    }

    func testTrailingSemicolon() {
        verifyRule(TrailingSemicolonRule.description)
    }

    func testTrailingWhitespace() {
        verifyRule(TrailingWhitespaceRule.description, commentDoesntViolate: false)
    }

    func testTypeBodyLength() {
        verifyRule(TypeBodyLengthRule.description)
    }

    func testTypeName() {
        verifyRule(TypeNameRule.description)
    }

    func testValidDocs() {
        verifyRule(ValidDocsRule.description)
    }

    func testVariableName() {
        verifyRule(VariableNameRule.description)
    }
}
