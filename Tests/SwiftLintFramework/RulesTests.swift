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

    // swiftlint:disable function_body_length
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
    // swiftlint:enable function_body_length

    func testComma() {
        verifyRule(CommaRule.description)
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

    func testMissingDocs() {
        verifyRule(MissingDocsRule.description)
    }

    func testNesting() {
        verifyRule(NestingRule.description)
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

    func testRedundantNilCoalesing() {
        verifyRule(RedundantNilCoalesingRule.description)
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
        verifyRule(description, ruleConfiguration: ["ignores_empty_lines": true],
                   commentDoesntViolate: false)
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

    func testSuperCall() {
        verifyRule(OverridenSuperCallRule.description)
    }

}
