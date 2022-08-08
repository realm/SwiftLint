@testable import SwiftLintFramework
import XCTest

class AttributesRuleTests: XCTestCase {
    func testAttributesWithDefaultConfiguration() async {
        // Test with default parameters
        await verifyRule(AttributesRule.description)
    }

    func testAttributesWithAlwaysOnSameLine() async {
        // Test with custom `always_on_same_line`
        let nonTriggeringExamples = [
            Example("@objc var x: String"),
            Example("@objc func foo()"),
            Example("@nonobjc\n func foo()"),
            Example("""
            class Foo {
                @objc private var object: RLMWeakObjectHandle?
                @objc private var property: RLMProperty?
            }
            """),
            Example("""
            @objc(XYZFoo) class Foo: NSObject {}
            """)
        ]
        let triggeringExamples = [
            Example("@objc\n ↓var x: String"),
            Example("@objc\n ↓func foo()"),
            Example("@nonobjc ↓func foo()")
        ]

        let alwaysOnSameLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        await verifyRule(alwaysOnSameLineDescription,
                         ruleConfiguration: ["always_on_same_line": ["@objc"]])
    }

    func testAttributesWithAlwaysOnLineAbove() async {
        // Test with custom `always_on_line_above`
        let nonTriggeringExamples = [
            Example("@objc\n var x: String"),
            Example("@objc\n func foo()"),
            Example("@nonobjc\n func foo()")
        ]
        let triggeringExamples = [
            Example("@objc ↓var x: String"),
            Example("@objc ↓func foo()"),
            Example("@nonobjc ↓func foo()")
        ]

        let alwaysOnNewLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        await verifyRule(alwaysOnNewLineDescription,
                         ruleConfiguration: ["always_on_line_above": ["@objc"]])
    }

    func testAttributesWithAttributesOnLineAboveButOnOtherDeclaration() async {
        let nonTriggeringExamples = [
            Example("""
            @IBDesignable open class TagListView: UIView {
                @IBInspectable open dynamic var textColor: UIColor = UIColor.white {
                    didSet {}
                }
            }
            """),
            Example("""
            @objc public protocol TagListViewDelegate {
                @objc optional func tagDidSelect(_ title: String, sender: TagListView)
                @objc optional func tagDidDeselect(_ title: String, sender: TagListView)
            }
            """)
        ]

        let triggeringExamples = [
            Example("""
            @IBDesignable open class TagListView: UIView {
                @IBInspectable
                open dynamic ↓var textColor: UIColor = UIColor.white {
                    didSet {}
                }
            }
            """),
            Example("""
            @objc public protocol TagListViewDelegate {
                @objc
                optional ↓func tagDidSelect(_ title: String, sender: TagListView)
                @objc optional func tagDidDeselect(_ title: String, sender: TagListView)
            }
            """)
        ]

        let alwaysOnNewLineDescription = AttributesRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        await verifyRule(alwaysOnNewLineDescription,
                         ruleConfiguration: ["always_on_same_line": ["@discardableResult", "@objc",
                                                                     "@IBAction", "@IBDesignable"]])
    }
}
