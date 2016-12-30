//
//  RulesTests.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SwiftLintFramework
import XCTest

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
class RulesTests: XCTestCase {

    func testClassDelegateProtocol() {
        verifyRule(ClassDelegateProtocolRule.description)
    }

    func testClosingBrace() {
        verifyRule(ClosingBraceRule.description)
    }

    func testComma() {
        verifyRule(CommaRule.description)
    }

    func testClosureEndIndentation() {
        verifyRule(ClosureEndIndentationRule.description)
    }

    func testClosureParameterPosition() {
        verifyRule(ClosureParameterPositionRule.description)
    }

    func testClosureSpacingRule() {
        verifyRule(ClosureSpacingRule.description)
    }

    func testConditionalReturnsOnNewline() {
        verifyRule(ConditionalReturnsOnNewline.description)
    }

    func testControlStatement() {
        verifyRule(ControlStatementRule.description)
    }

    func testCyclomaticComplexity() {
        verifyRule(CyclomaticComplexityRule.description)
    }

    func testDynamicInline() {
        verifyRule(DynamicInlineRule.description)
    }

    func testEducatedSorting() {
        verifyRule(EducatedSortingRule.description)
    }

    func testEmptyCount() {
        verifyRule(EmptyCountRule.description)
    }

    func testEmptyParameters() {
        verifyRule(EmptyParametersRule.description)
    }

    func testEmptyParenthesesWithTrailingClosure() {
        verifyRule(EmptyParenthesesWithTrailingClosureRule.description)
    }

    func testExplicitInit() {
        verifyRule(ExplicitInitRule.description)
    }

    func testFileLength() {
        verifyRule(FileLengthRule.description, commentDoesntViolate: false,
                   testMultiByteOffsets: false)
    }

    func testFirstWhere() {
        verifyRule(FirstWhereRule.description)
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

    func testImplicitGetterRule() {
        verifyRule(ImplicitGetterRule.description)
    }

    func testLeadingWhitespace() {
        verifyRule(LeadingWhitespaceRule.description, testMultiByteOffsets: false)
    }

    func testLegacyCGGeometryFunctions() {
        verifyRule(LegacyCGGeometryFunctionsRule.description)
    }

    func testLegacyNSGeometryFunctions() {
        verifyRule(LegacyNSGeometryFunctionsRule.description)
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

    func testMark() {
        verifyRule(MarkRule.description, commentDoesntViolate: false)
    }

// swiftlint:disable:next todo
// FIXME: https://github.com/jpsim/SourceKitten/issues/269
//    func testMissingDocs() {
//        verifyRule(MissingDocsRule.description)
//    }

    func testNesting() {
        verifyRule(NestingRule.description)
    }

    func testNimbleOperator() {
        verifyRule(NimbleOperatorRule.description)
    }

    func testNumberSeparator() {
        verifyRule(NumberSeparatorRule.description)
    }

    func testVerticalWhitespace() {
        verifyRule(VerticalWhitespaceRule.description)
    }

    func testOpeningBrace() {
        verifyRule(OpeningBraceRule.description)
    }

    func testOperatorFunctionWhitespace() {
        verifyRule(OperatorFunctionWhitespaceRule.description)
    }

    func testOperatorUsageWhitespace() {
        verifyRule(OperatorUsageWhitespaceRule.description)
    }

    func testPrivateOutlet() {
        verifyRule(PrivateOutletRule.description)

        let baseDescription = PrivateOutletRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            "class Foo {\n  @IBOutlet private(set) var label: UILabel?\n}\n",
            "class Foo {\n  @IBOutlet private(set) var label: UILabel!\n}\n",
            "class Foo {\n  @IBOutlet weak private(set) var label: UILabel?\n}\n",
            "class Foo {\n  @IBOutlet private(set) weak var label: UILabel?\n}\n"
        ]
        let description = RuleDescription(identifier: baseDescription.identifier,
                                          name: baseDescription.name,
                                          description: baseDescription.description,
                                          nonTriggeringExamples: nonTriggeringExamples,
                                          triggeringExamples: baseDescription.triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allow_private_set": true])
    }

    func testPrivateUnitTest() {
        verifyRule(PrivateUnitTestRule.description)
    }

    func testProhibitedSuper() {
        verifyRule(ProhibitedSuperRule.description)
    }

    func testRedundantNilCoalescing() {
        verifyRule(RedundantNilCoalescingRule.description)
    }

    func testRedundantOptionalInitialization() {
        verifyRule(RedundantOptionalInitializationRule.description)
    }

    func testRedundantStringEnumValue() {
        verifyRule(RedundantStringEnumValueRule.description)
    }

    func testRedundantVoidReturn() {
        verifyRule(RedundantVoidReturnRule.description)
    }

    func testReturnArrowWhitespace() {
        verifyRule(ReturnArrowWhitespaceRule.description)
    }

    func testSortedImports() {
        verifyRule(SortedImportsRule.description)
    }

    func testStatementPosition() {
        verifyRule(StatementPositionRule.description)
    }

    func testStatementPositionUncuddled() {
        let configuration = ["statement_mode": "uncuddled_else"]
        verifyRule(StatementPositionRule.uncuddledDescription, ruleConfiguration: configuration)
    }

    func testSwitchCaseOnNewline() {
        verifyRule(SwitchCaseOnNewlineRule.description)
    }

    func testSyntacticSugar() {
        verifyRule(SyntacticSugarRule.description)
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
        verifyRule(TrailingWhitespaceRule.description)

        // Perform additional tests with the ignores_empty_lines setting enabled.
        // The set of non-triggering examples is extended by a whitespace-indented empty line
        let baseDescription = TrailingWhitespaceRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [" \n"]
        let description = RuleDescription(identifier: baseDescription.identifier,
                                                name: baseDescription.name,
                                         description: baseDescription.description,
                               nonTriggeringExamples: nonTriggeringExamples,
                                  triggeringExamples: baseDescription.triggeringExamples,
                                         corrections: baseDescription.corrections)
        verifyRule(description,
                   ruleConfiguration: ["ignores_empty_lines": true, "ignores_comments": true])

        // Perform additional tests with the ignores_comments settings disabled.
        let triggeringComments = ["// \n", "let name: String // \n"]
        let baseDescription2 = TrailingWhitespaceRule.description
        let nonTriggeringExamples2 = baseDescription2.nonTriggeringExamples
            .filter { !triggeringComments.contains($0) }
        let triggeringExamples2 = baseDescription2.triggeringExamples + triggeringComments
        let description2 = RuleDescription(identifier: baseDescription2.identifier,
                                           name: baseDescription2.name,
                                           description: baseDescription2.description,
                                           nonTriggeringExamples: nonTriggeringExamples2,
                                           triggeringExamples: triggeringExamples2,
                                           corrections: baseDescription2.corrections)
        verifyRule(description2,
                   ruleConfiguration: ["ignores_empty_lines": false, "ignores_comments": false],
                   commentDoesntViolate: false)
    }

    func testTypeBodyLength() {
        verifyRule(TypeBodyLengthRule.description)
    }

    func testTypeName() {
        verifyRule(TypeNameRule.description)
    }

    func testUnusedClosureParameter() {
        verifyRule(UnusedClosureParameterRule.description)
    }

    func testUnusedEnumerated() {
        verifyRule(UnusedEnumeratedRule.description)
    }

// swiftlint:disable:next todo
// FIXME: https://github.com/jpsim/SourceKitten/issues/269
//    func testValidDocs() {
//        verifyRule(ValidDocsRule.description)
//    }

    func testValidIBInspectable() {
        verifyRule(ValidIBInspectableRule.description)
    }

    func testVariableName() {
        verifyRule(VariableNameRule.description)
    }

    func testVerticalParameterAlignment() {
        verifyRule(VerticalParameterAlignmentRule.description)
    }

    func testVoidReturn() {
        verifyRule(VoidReturnRule.description)
    }

    func testSuperCall() {
        verifyRule(OverriddenSuperCallRule.description)
    }

    func testWeakDelegate() {
        verifyRule(WeakDelegateRule.description)
    }

}

extension RulesTests {
    static var allTests: [(String, (RulesTests) -> () throws -> Void)] {
        return [
            ("testClassDelegateProtocol", testClassDelegateProtocol),
            ("testClosingBrace", testClosingBrace),
            ("testComma", testComma),
            ("testClosureEndIndentation", testClosureEndIndentation),
            ("testClosureParameterPosition", testClosureParameterPosition),
            ("testClosureSpacingRule", testClosureSpacingRule),
            ("testConditionalReturnsOnNewline", testConditionalReturnsOnNewline),
            ("testControlStatement", testControlStatement),
            ("testCyclomaticComplexity", testCyclomaticComplexity),
            ("testDynamicInline", testDynamicInline),
            ("testEmptyCount", testEmptyCount),
            ("testEmptyParameters", testEmptyParameters),
            ("testEmptyParenthesesWithTrailingClosure", testEmptyParenthesesWithTrailingClosure),
            ("testExplicitInit", testExplicitInit),
            ("testFileLength", testFileLength),
            ("testFirstWhere", testFirstWhere),
            ("testForceCast", testForceCast),
            ("testForceTry", testForceTry),
            // ("testForceUnwrapping", testForceUnwrapping),
            ("testFunctionBodyLength", testFunctionBodyLength),
            ("testFunctionParameterCountRule", testFunctionParameterCountRule),
            ("testImplicitGetterRule", testImplicitGetterRule),
            ("testLeadingWhitespace", testLeadingWhitespace),
            ("testLegacyCGGeometryFunctions", testLegacyCGGeometryFunctions),
            ("testLegacyNSGeometryFunctions", testLegacyNSGeometryFunctions),
            ("testLegacyConstant", testLegacyConstant),
            ("testLegacyConstructor", testLegacyConstructor),
            ("testLineLength", testLineLength),
            ("testMark", testMark),
            ("testNesting", testNesting),
            ("testNimbleOperator", testNimbleOperator),
            ("testNumberSeparator", testNumberSeparator),
            ("testVerticalWhitespace", testVerticalWhitespace),
            ("testOpeningBrace", testOpeningBrace),
            ("testOperatorFunctionWhitespace", testOperatorFunctionWhitespace),
            ("testOperatorUsageWhitespace", testOperatorUsageWhitespace),
            ("testPrivateOutlet", testPrivateOutlet),
            ("testPrivateUnitTest", testPrivateUnitTest),
            ("testProhibitedSuper", testProhibitedSuper),
            ("testRedundantNilCoalescing", testRedundantNilCoalescing),
            ("testRedundantOptionalInitialization", testRedundantOptionalInitialization),
            ("testRedundantStringEnumValue", testRedundantStringEnumValue),
            ("testRedundantVoidReturn", testRedundantVoidReturn),
            ("testReturnArrowWhitespace", testReturnArrowWhitespace),
            ("testSortedImports", testSortedImports),
            ("testStatementPosition", testStatementPosition),
            ("testStatementPositionUncuddled", testStatementPositionUncuddled),
            ("testSwitchCaseOnNewline", testSwitchCaseOnNewline),
            ("testSyntacticSugar", testSyntacticSugar),
            ("testTodo", testTodo),
            ("testTrailingNewline", testTrailingNewline),
            ("testTrailingSemicolon", testTrailingSemicolon),
            ("testTrailingWhitespace", testTrailingWhitespace),
            ("testTypeBodyLength", testTypeBodyLength),
            ("testTypeName", testTypeName),
            ("testUnusedClosureParameter", testUnusedClosureParameter),
            ("testUnusedEnumerated", testUnusedEnumerated),
            ("testValidIBInspectable", testValidIBInspectable),
            ("testVariableName", testVariableName),
            ("VerticalParameterAlignmentRule", testVerticalParameterAlignment),
            ("testVoidReturn", testVoidReturn),
            ("testSuperCall", testSuperCall),
            ("testWeakDelegate", testWeakDelegate)
        ]
    }
}
