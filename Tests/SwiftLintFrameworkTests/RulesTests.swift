import SwiftLintFramework
import XCTest

class RulesTests: XCTestCase {
    func testLeadingWhitespace() {
        verifyRule(LeadingWhitespaceRule.description, skipDisableCommandTests: true,
                   testMultiByteOffsets: false, testShebang: false)
    }

    func testMark() {
        verifyRule(MarkRule.description, skipCommentTests: true)
    }

    func testMissingDocs() {
        verifyRule(MissingDocsRule.description)
    }

    func testModifierOrder() {
        verifyRule(ModifierOrderRule.description)
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

    func testRequiredEnumCase() {
        let configuration = ["NetworkResponsable": ["notConnected": "error"]]
        verifyRule(RequiredEnumCaseRule.description, ruleConfiguration: configuration)
    }

    func testTrailingNewline() {
        verifyRule(TrailingNewlineRule.description, commentDoesntViolate: false,
                   stringDoesntViolate: false)
    }
}
