@testable import SwiftLintFramework
import XCTest

class AttributesRuleTests: XCTestCase {
    func testAttributesWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(AttributesRule.description)
    }

    func testAttributesWithAlwaysOnSameLine() {
        // Test with custom `always_on_same_line`
        let nonTriggeringExamples = [
            "@objc var x: String",
            "@objc func foo()",
            "@nonobjc\n func foo()",
            "class Foo {\n" +
                "@objc private var object: RLMWeakObjectHandle?\n" +
                "@objc private var property: RLMProperty?\n" +
            "}"
        ]
        let triggeringExamples = [
            "@objc\n ↓var x: String",
            "@objc\n ↓func foo()",
            "@nonobjc ↓func foo()"
        ]

        let alwaysOnSameLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(alwaysOnSameLineDescription,
                   ruleConfiguration: ["always_on_same_line": ["@objc"]])
    }

    func testAttributesWithAlwaysOnLineAbove() {
        // Test with custom `always_on_line_above`
        let nonTriggeringExamples = [
            "@objc\n var x: String",
            "@objc\n func foo()",
            "@nonobjc\n func foo()"
        ]
        let triggeringExamples = [
            "@objc ↓var x: String",
            "@objc ↓func foo()",
            "@nonobjc ↓func foo()"
        ]

        let alwaysOnNewLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(alwaysOnNewLineDescription,
                   ruleConfiguration: ["always_on_line_above": ["@objc"]])
    }

    func testAttributesWithAttributesOnLineAboveButOnOtherDeclaration() {
        let nonTriggeringExamples = [
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
            """
        ]

        let triggeringExamples = [
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
            """
        ]

        let alwaysOnNewLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(alwaysOnNewLineDescription,
                   ruleConfiguration: ["always_on_same_line": ["@discardableResult", "@objc",
                                                               "@IBAction", "@IBDesignable"]])
    }
}
