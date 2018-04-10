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
// swiftlint:disable type_body_length

class RulesTests: XCTestCase {

    func testArrayInit() {
        verifyRule(ArrayInitRule.description)
    }

    func testBlockBasedKVO() {
        verifyRule(BlockBasedKVORule.description)
    }

    func testClassDelegateProtocol() {
        verifyRule(ClassDelegateProtocolRule.description)
    }

    func testClosingBrace() {
        verifyRule(ClosingBraceRule.description)
    }

    func testClosureEndIndentation() {
        verifyRule(ClosureEndIndentationRule.description)
    }

    func testClosureParameterPosition() {
        verifyRule(ClosureParameterPositionRule.description)
    }

    func testClosureSpacing() {
        verifyRule(ClosureSpacingRule.description)
    }

    func testComma() {
        verifyRule(CommaRule.description)
    }

    func testCompilerProtocolInit() {
        verifyRule(CompilerProtocolInitRule.description)
    }

    func testConditionalReturnsOnNewline() {
        verifyRule(ConditionalReturnsOnNewlineRule.description)
    }

    func testContainsOverFirstNotNil() {
        verifyRule(ContainsOverFirstNotNilRule.description)
    }

    func testControlStatement() {
        verifyRule(ControlStatementRule.description)
    }

    func testCyclomaticComplexity() {
        verifyRule(CyclomaticComplexityRule.description)
    }

    func testDiscardedNotificationCenterObserver() {
        verifyRule(DiscardedNotificationCenterObserverRule.description)
    }

    func testDiscouragedObjectLiteral() {
        verifyRule(DiscouragedObjectLiteralRule.description)
    }

    func testDiscouragedOptionalBoolean() {
        verifyRule(DiscouragedOptionalBooleanRule.description)
    }

    func testDiscouragedOptionalCollection() {
        verifyRule(DiscouragedOptionalCollectionRule.description)
    }

    func testDynamicInline() {
        verifyRule(DynamicInlineRule.description)
    }

    func testEmptyCount() {
        verifyRule(EmptyCountRule.description)
    }

    func testEmptyEnumArguments() {
        verifyRule(EmptyEnumArgumentsRule.description)
    }

    func testEmptyParameters() {
        verifyRule(EmptyParametersRule.description)
    }

    func testLowerACLThanParent() {
        verifyRule(LowerACLThanParentRule.description)
    }

    func testEmptyParenthesesWithTrailingClosure() {
        verifyRule(EmptyParenthesesWithTrailingClosureRule.description)
    }

    func testEmptyString() {
        verifyRule(EmptyStringRule.description)
    }

    func testExplicitACL() {
        verifyRule(ExplicitACLRule.description)
    }

    func testExplicitEnumRawValue() {
        verifyRule(ExplicitEnumRawValueRule.description)
    }

    func testExplicitInit() {
        verifyRule(ExplicitInitRule.description)
    }

    func testExplicitTopLevelACL() {
        verifyRule(ExplicitTopLevelACLRule.description)
    }

    func testExtensionAccessModifier() {
        verifyRule(ExtensionAccessModifierRule.description)
    }

    func testFallthrough() {
        verifyRule(FallthroughRule.description)
    }

    func testFatalErrorMessage() {
        verifyRule(FatalErrorMessageRule.description)
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

    func testForWhere() {
        verifyRule(ForWhereRule.description)
    }

    func testFunctionBodyLength() {
        verifyRule(FunctionBodyLengthRule.description)
    }

    func testFunctionParameterCount() {
        verifyRule(FunctionParameterCountRule.description)
    }

    func testImplicitGetter() {
        verifyRule(ImplicitGetterRule.description)
    }

    func testImplicitlyUnwrappedOptional() {
        verifyRule(ImplicitlyUnwrappedOptionalRule.description)
    }

    func testImplicitReturn() {
        verifyRule(ImplicitReturnRule.description)
    }

    func testIsDisjoint() {
        verifyRule(IsDisjointRule.description)
    }

    func testJoinedDefaultParameter() {
        verifyRule(JoinedDefaultParameterRule.description)
    }

    func testLargeTuple() {
        verifyRule(LargeTupleRule.description)
    }

    func testLeadingWhitespace() {
        verifyRule(LeadingWhitespaceRule.description, skipDisableCommandTests: true,
                   testMultiByteOffsets: false, testShebang: false)
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

    func testLetVarWhitespace() {
        verifyRule(LetVarWhitespaceRule.description)
    }

    func testLiteralExpressionEndIdentation() {
        verifyRule(LiteralExpressionEndIdentationRule.description)
    }

    func testMark() {
        verifyRule(MarkRule.description, skipCommentTests: true)
    }

    func testMultilineParameters() {
        verifyRule(MultilineParametersRule.description)
    }

    func testMultipleClosuresWithTrailingClosure() {
        verifyRule(MultipleClosuresWithTrailingClosureRule.description)
    }

    func testNesting() {
        verifyRule(NestingRule.description)
    }

    func testNoExtensionAccessModifier() {
        verifyRule(NoExtensionAccessModifierRule.description)
    }

    func testNoGroupingExtension() {
        verifyRule(NoGroupingExtensionRule.description)
    }

    func testNotificationCenterDetachment() {
        verifyRule(NotificationCenterDetachmentRule.description)
    }

    func testNimbleOperator() {
        verifyRule(NimbleOperatorRule.description)
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

    func testOverrideInExtension() {
        verifyRule(OverrideInExtensionRule.description)
    }

    func testPatternMatchingKeywords() {
        verifyRule(PatternMatchingKeywordsRule.description)
    }

    func testPrefixedTopLevelConstant() {
        verifyRule(PrefixedTopLevelConstantRule.description)
    }

    func testPrivateAction() {
        verifyRule(PrivateActionRule.description)
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

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allow_private_set": true])
    }

    func testPrivateUnitTest() {
        verifyRule(PrivateUnitTestRule.description)
    }

    func testProhibitedSuper() {
        verifyRule(ProhibitedSuperRule.description)
    }

    func testProtocolPropertyAccessorsOrder() {
        verifyRule(ProtocolPropertyAccessorsOrderRule.description)
    }

    func testQuickDiscouragedCall() {
        verifyRule(QuickDiscouragedCallRule.description)
    }

    func testQuickDiscouragedFocusedTest() {
        verifyRule(QuickDiscouragedFocusedTestRule.description)
    }

    func testQuickDiscouragedPendingTest() {
        verifyRule(QuickDiscouragedPendingTestRule.description)
    }

    func testRedundantDiscardableLet() {
        verifyRule(RedundantDiscardableLetRule.description)
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

    func testRequiredEnumCase() {
        let configuration = ["NetworkResponsable": ["notConnected": "error"]]
        verifyRule(RequiredEnumCaseRule.description, ruleConfiguration: configuration)
    }

    func testReturnArrowWhitespace() {
        verifyRule(ReturnArrowWhitespaceRule.description)
    }

    func testShorthandOperator() {
        verifyRule(ShorthandOperatorRule.description)
    }

    func testSingleTestClass() {
        verifyRule(SingleTestClassRule.description)
    }

    func testSortedFirstLast() {
        verifyRule(SortedFirstLastRule.description)
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

    func testStrictFilePrivate() {
        verifyRule(StrictFilePrivateRule.description)
    }

    func testSwitchCaseAlignment() {
        verifyRule(SwitchCaseAlignmentRule.description)
    }

    func testSwitchCaseOnNewline() {
        verifyRule(SwitchCaseOnNewlineRule.description)
    }

    func testSyntacticSugar() {
        verifyRule(SyntacticSugarRule.description)
    }

    func testTrailingClosure() {
        verifyRule(TrailingClosureRule.description)
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
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description,
                   ruleConfiguration: ["ignores_empty_lines": true, "ignores_comments": true])

        // Perform additional tests with the ignores_comments settings disabled.
        let triggeringComments = ["// \n", "let name: String // \n"]
        let nonTriggeringExamples2 = baseDescription.nonTriggeringExamples
            .filter { !triggeringComments.contains($0) }
        let triggeringExamples2 = baseDescription.triggeringExamples + triggeringComments
        let description2 = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples2)
                                          .with(triggeringExamples: triggeringExamples2)
        verifyRule(description2,
                   ruleConfiguration: ["ignores_empty_lines": false, "ignores_comments": false],
                   commentDoesntViolate: false)
    }

    func testTypeBodyLength() {
        verifyRule(TypeBodyLengthRule.description)
    }

    func testUnneededBreakInSwitch() {
        verifyRule(UnneededBreakInSwitchRule.description)
    }

    func testUnneededParenthesesInClosureArgument() {
        verifyRule(UnneededParenthesesInClosureArgumentRule.description)
    }

    func testUntypedErrorInCatch() {
        verifyRule(UntypedErrorInCatchRule.description)
    }

    func testUnusedClosureParameter() {
        verifyRule(UnusedClosureParameterRule.description)
    }

    func testUnusedEnumerated() {
        verifyRule(UnusedEnumeratedRule.description)
    }

    func testValidIBInspectable() {
        verifyRule(ValidIBInspectableRule.description)
    }

    func testVerticalParameterAlignmentOnCall() {
        verifyRule(VerticalParameterAlignmentOnCallRule.description)
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

    func testXCTFailMessage() {
        verifyRule(XCTFailMessageRule.description)
    }

    func testYodaCondition() {
        verifyRule(YodaConditionRule.description)
    }
}
