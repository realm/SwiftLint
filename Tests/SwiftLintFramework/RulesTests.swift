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

    // protocol XCTestCaseProvider
    lazy var allTests: [(String, () throws -> Void)] = [
        ("testClosingBrace", self.testClosingBrace),
        ("testColon", self.testColon),
        ("testComma", self.testComma),
        ("testConditionalBindingCascade", self.testConditionalBindingCascade),
        ("testControlStatement", self.testControlStatement),
        ("testCyclomaticComplexity", self.testCyclomaticComplexity),
        ("testEmptyCount", self.testEmptyCount),
        ("testFileLength", self.testFileLength),
        ("testForceCast", self.testForceCast),
        ("testForceTry", self.testForceTry),
        ("testForceUnwrapping", self.testForceUnwrapping),
        ("testFunctionBodyLength", self.testFunctionBodyLength),
        ("testFunctionParameterCountRule", self.testFunctionParameterCountRule),
        ("testLeadingWhitespace", self.testLeadingWhitespace),
        ("testLegacyConstant", self.testLegacyConstant),
        ("testLegacyConstructor", self.testLegacyConstructor),
        ("testLineLength", self.testLineLength),
        ("testMissingDocs", self.testMissingDocs),
        ("testNesting", self.testNesting),
        ("testOpeningBrace", self.testOpeningBrace),
        ("testOperatorFunctionWhitespace", self.testOperatorFunctionWhitespace),
        ("testReturnArrowWhitespace", self.testReturnArrowWhitespace),
        ("testStatementPosition", self.testStatementPosition),
        ("testTodo", self.testTodo),
        ("testTrailingNewline", self.testTrailingNewline),
        ("testTrailingSemicolon", self.testTrailingSemicolon),
        ("testTrailingWhitespace", self.testTrailingWhitespace),
        ("testTypeBodyLength", self.testTypeBodyLength),
        ("testTypeName", self.testTypeName),
        ("testValidDocs", self.testValidDocs),
        ("testVariableName", self.testVariableName),
    ]

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
