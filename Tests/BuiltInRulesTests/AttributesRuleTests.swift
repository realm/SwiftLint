import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct AttributesRuleTests {
    @Test
    func attributesWithAlwaysOnSameLine() {
        // Test with custom `always_on_same_line`
        let nonTriggeringExamples = #examples([
            "@objc var x: String",
            "@objc func foo()",
            "@nonobjc\n func foo()",
            """
            class Foo {
                @objc private var object: RLMWeakObjectHandle?
                @objc private var property: RLMProperty?
            }
            """,
            """
            @objc(XYZFoo) class Foo: NSObject {}
            """,
        ])
        let triggeringExamples = #examples([
            "@objc\n ↓var x: String",
            "@objc\n ↓func foo()",
            "@nonobjc ↓func foo()",
        ])

        let alwaysOnSameLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(
            alwaysOnSameLineDescription,
            ruleConfiguration: ["always_on_same_line": ["@objc"]])
    }

    @Test
    func attributesWithAlwaysOnLineAbove() {
        // Test with custom `always_on_line_above`
        let nonTriggeringExamples = #examples([
            "@objc\n var x: String",
            "@objc\n func foo()",
            "@nonobjc\n func foo()",
        ])
        let triggeringExamples = #examples([
            "@objc ↓var x: String",
            "@objc ↓func foo()",
            "@nonobjc ↓func foo()",
        ])

        let alwaysOnNewLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(
            alwaysOnNewLineDescription,
            ruleConfiguration: ["always_on_line_above": ["@objc"]])
    }

    @Test
    func attributesWithAttributesOnLineAboveButOnOtherDeclaration() {
        let nonTriggeringExamples = #examples([
            """
            @IBDesignable open class TagListView: UIView {
                @IBInspectable open dynamic var textColor: UIColor = UIColor.white {
                    didSet {}
                }
            }
            """,
            """
            @objc public protocol TagListViewDelegate {
                @objc optional func tagDidSelect(_ title: String, sender: TagListView)
                @objc optional func tagDidDeselect(_ title: String, sender: TagListView)
            }
            """,
        ])

        let triggeringExamples = #examples([
            """
            @IBDesignable open class TagListView: UIView {
                @IBInspectable
                open dynamic ↓var textColor: UIColor = UIColor.white {
                    didSet {}
                }
            }
            """,
            """
            @objc public protocol TagListViewDelegate {
                @objc
                optional ↓func tagDidSelect(_ title: String, sender: TagListView)
                @objc optional func tagDidDeselect(_ title: String, sender: TagListView)
            }
            """,
        ])

        let alwaysOnNewLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(
            alwaysOnNewLineDescription,
            ruleConfiguration: [
                "always_on_same_line": [
                    "@discardableResult", "@objc", "@IBAction", "@IBDesignable",
                ],
            ]
        )
    }

    @Test
    func attributesWithArgumentsAlwaysOnLineAboveFalse() {
        let nonTriggeringExamples = #examples([
            "@Environment(\\.presentationMode) private var presentationMode"
        ])
        let triggeringExamples = #examples([
            """
            @Environment(\\.presentationMode)
            private ↓var presentationMode
            """,
        ])

        let argumentsAlwaysOnLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(
            argumentsAlwaysOnLineDescription,
            ruleConfiguration: ["attributes_with_arguments_always_on_line_above": false])
    }

    @Test
    func attributesWithArgumentsAlwaysOnLineAboveTrue() {
        let nonTriggeringExamples = #examples([
            "@Environment(\\.presentationMode)\nprivate var presentationMode"
        ])
        let triggeringExamples = #examples([
            "@Environment(\\.presentationMode) private ↓var presentationMode"
        ])

        let argumentsAlwaysOnLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(
            argumentsAlwaysOnLineDescription,
            ruleConfiguration: ["attributes_with_arguments_always_on_line_above": true])
    }
}
