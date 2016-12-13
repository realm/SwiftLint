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

    func testClosingBrace() {
        verifyRule(ClosingBraceRule.description)
    }

    // swiftlint:disable:next function_body_length
    func testColon() {
        // Verify Colon rule with test values for when flexible_right_spacing
        // is false (default).
        verifyRule(ColonRule.description)

        // Verify Colon rule with test values for when flexible_right_spacing
        // is true.
        let description = RuleDescription(
            identifier: "colon",
            name: "Colon",
            description: "Colons should be next to the identifier when specifying a type.",
            nonTriggeringExamples: [
                "let abc: Void\n",
                "let abc: [Void: Void]\n",
                "let abc: (Void, Void)\n",
                "let abc: ([Void], String, Int)\n",
                "let abc: [([Void], String, Int)]\n",
                "let abc: String=\"def\"\n",
                "let abc: Int=0\n",
                "let abc: Enum=Enum.Value\n",
                "func abc(def: Void) {}\n",
                "func abc(def: Void, ghi: Void) {}\n",
                "// 周斌佳年周斌佳\nlet abc: String = \"abc:\"",
                "let abc:  Void\n",
                "let abc:  (Void, String, Int)\n",
                "let abc:  ([Void], String, Int)\n",
                "let abc:  [([Void], String, Int)]\n",
                "func abc(def:  Void) {}\n"
            ],
            triggeringExamples: [
                "let ↓abc:Void\n",
                "let ↓abc :Void\n",
                "let ↓abc : Void\n",
                "let ↓abc : [Void: Void]\n",
                "let ↓abc : (Void, String, Int)\n",
                "let ↓abc : ([Void], String, Int)\n",
                "let ↓abc : [([Void], String, Int)]\n",
                "let ↓abc :String=\"def\"\n",
                "let ↓abc :Int=0\n",
                "let ↓abc :Int = 0\n",
                "let ↓abc:Int=0\n",
                "let ↓abc:Int = 0\n",
                "let ↓abc:Enum=Enum.Value\n",
                "func abc(↓def:Void) {}\n",
                "func abc(↓def :Void) {}\n",
                "func abc(↓def : Void) {}\n",
                "func abc(def: Void, ↓ghi :Void) {}\n"
            ],
            corrections: [
                "let abc:Void\n": "let abc: Void\n",
                "let abc :Void\n": "let abc: Void\n",
                "let abc : Void\n": "let abc: Void\n",
                "let abc : [Void: Void]\n": "let abc: [Void: Void]\n",
                "let abc : (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
                "let abc : ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
                "let abc : [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
                "let abc :String=\"def\"\n": "let abc: String=\"def\"\n",
                "let abc :Int=0\n": "let abc: Int=0\n",
                "let abc :Int = 0\n": "let abc: Int = 0\n",
                "let abc:Int=0\n": "let abc: Int=0\n",
                "let abc:Int = 0\n": "let abc: Int = 0\n",
                "let abc:Enum=Enum.Value\n": "let abc: Enum=Enum.Value\n",
                "func abc(def:Void) {}\n": "func abc(def: Void) {}\n",
                "func abc(def :Void) {}\n": "func abc(def: Void) {}\n",
                "func abc(def : Void) {}\n": "func abc(def: Void) {}\n",
                "func abc(def: Void, ghi :Void) {}\n": "func abc(def: Void, ghi: Void) {}\n"
            ]
        )

        verifyRule(description, ruleConfiguration: ["flexible_right_spacing": true])
    }

    func testComma() {
        verifyRule(CommaRule.description)
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

    func testEmptyCount() {
        verifyRule(EmptyCountRule.description)
    }

    func testEmptyParenthesesWithTrailingClosure() {
        verifyRule(EmptyParenthesesWithTrailingClosureRule.description)
    }

    func testExplicitInit() {
        verifyRule(ExplicitInitRule.description)
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

    func testImplicitGetterRule() {
        verifyRule(ImplicitGetterRule.description)
    }

    func testLeadingWhitespace() {
        verifyRule(LeadingWhitespaceRule.description)
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

    func testRedundantStringEnumValue() {
        verifyRule(RedundantStringEnumValueRule.description)
    }

    func testReturnArrowWhitespace() {
        verifyRule(ReturnArrowWhitespaceRule.description)
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

    func testTrailingComma() {
        // verify with mandatory_comma = false (default value)
        verifyRule(TrailingCommaRule.description)

        // verify with mandatory_comma = true
        let mandatoryCommaDescription = RuleDescription(
            identifier: "trailing_comma",
            name: "Trailing Comma",
            description: "Trailing commas in arrays and dictionaries should be enforced.",
            nonTriggeringExamples: [
                "let foo = []\n",
                "let foo = [:]\n",
                "let foo = [1, 2, 3,]\n",
                "let foo = [1, 2, 3, ]\n",
                "let foo = [1, 2, 3   ,]\n",
                "let foo = [1: 2, 2: 3, ]\n",
                "struct Bar {\n let foo = [1: 2, 2: 3,]\n}\n",
                "let foo = [Void]()\n",
                "let foo = [(Void, Void)]()\n",
                "let foo = [1, 2, 3]\n",
                "let foo = [1: 2, 2: 3]\n",
                "let foo = [1: 2, 2: 3   ]\n",
                "struct Bar {\n let foo = [1: 2, 2: 3]\n}\n",
                "let foo = [1, 2, 3] + [4, 5, 6]\n"
            ],
            triggeringExamples: [
                "let foo = [1, 2,\n 3↓]\n",
                "let foo = [1: 2,\n 2: 3↓]\n",
                "let foo = [1: 2,\n 2: 3↓   ]\n",
                "struct Bar {\n let foo = [1: 2,\n 2: 3↓]\n}\n",
                "let foo = [1, 2,\n 3↓] + [4,\n 5, 6↓]\n"
            ]
        )

        verifyRule(mandatoryCommaDescription, ruleConfiguration: ["mandatory_comma": true])
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
            ("testClosingBrace", testClosingBrace),
            ("testColon", testColon),
            ("testComma", testComma),
            ("testClosureParameterPosition", testClosureParameterPosition),
            ("testClosureSpacingRule", testClosureSpacingRule),
            ("testConditionalReturnsOnNewline", testConditionalReturnsOnNewline),
            ("testControlStatement", testControlStatement),
            ("testCyclomaticComplexity", testCyclomaticComplexity),
            ("testDynamicInline", testDynamicInline),
            ("testEmptyCount", testEmptyCount),
            ("testEmptyParenthesesWithTrailingClosure", testEmptyParenthesesWithTrailingClosure),
            ("testExplicitInit", testExplicitInit),
            ("testFileLength", testFileLength),
            ("testForceCast", testForceCast),
            ("testForceTry", testForceTry),
            // ("testForceUnwrapping", testForceUnwrapping),
            ("testFunctionBodyLength", testFunctionBodyLength),
            ("testFunctionParameterCountRule", testFunctionParameterCountRule),
            ("testImplicitGetterRule", testImplicitGetterRule),
            // ("testLeadingWhitespace", testLeadingWhitespace),
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
            ("testPrivateOutlet", testPrivateOutlet),
            // ("testPrivateUnitTest", testPrivateUnitTest),
            ("testProhibitedSuper", testProhibitedSuper),
            ("testRedundantNilCoalescing", testRedundantNilCoalescing),
            ("testRedundantStringEnumValue", testRedundantStringEnumValue),
            ("testReturnArrowWhitespace", testReturnArrowWhitespace),
            ("testStatementPosition", testStatementPosition),
            ("testStatementPositionUncuddled", testStatementPositionUncuddled),
            ("testSwitchCaseOnNewline", testSwitchCaseOnNewline),
            ("testSyntacticSugar", testSyntacticSugar),
            ("testTodo", testTodo),
            ("testTrailingComma", testTrailingComma),
            ("testTrailingNewline", testTrailingNewline),
            ("testTrailingSemicolon", testTrailingSemicolon),
            ("testTrailingWhitespace", testTrailingWhitespace),
            ("testTypeBodyLength", testTypeBodyLength),
            // ("testTypeName", testTypeName),
            ("testValidIBInspectable", testValidIBInspectable),
            // ("testVariableName", testVariableName),
            ("testSuperCall", testSuperCall),
            ("testWeakDelegate", testWeakDelegate)
        ]
    }
}
