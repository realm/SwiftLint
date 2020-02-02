@testable import SwiftLintFramework
import XCTest

// swiftlint:disable file_length type_body_length

class ModifierOrderTests: XCTestCase {
    func testAttributeTypeMethod() {
        let descriptionOverride = RuleDescription(
            identifier: "modifier_order",
            name: "Modifier Order",
            description: "Modifier order should be consistent.",
            kind: .style,
            minSwiftVersion: .fourDotOne,
            nonTriggeringExamples: [
                Example("""
                public class SomeClass {
                   class public func someFunc() {}
                }
                """),
                Example("""
                public class SomeClass {
                   static public func someFunc() {}
                }
                """)
            ],
            triggeringExamples: [
                Example("""
                public class SomeClass {
                   public class func someFunc() {}
                }
                """),
                Example("""
                public class SomeClass {
                   public static func someFunc() {}
                }
                """)
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["typeMethods", "acl"]])
    }

    func testRightOrderedModifierGroups() {
        let descriptionOverride = RuleDescription(
            identifier: "modifier_order",
            name: "Modifier Order",
            description: "Modifier order should be consistent.",
            kind: .style,
            minSwiftVersion: .fourDotOne,
            nonTriggeringExamples: [
                Example("public protocol Foo: class {}\n" +
                "public weak internal(set) var bar: Foo? \n"),
                Example("open final class Foo {" +
                "  fileprivate static  func bar() {} \n" +
                "  open class func barFoo() {} }"),
                Example("public struct Foo {" +
                "  private mutating func bar() {} }")
            ],
            triggeringExamples: [
                Example("public protocol Foo: class {} \n" +
                "public internal(set) weak var bar: Foo? \n"),
                Example("final public class Foo {" +
                "  static fileprivate func bar() {} \n" +
                "  class open func barFoo() {} }"),
                Example("public struct Foo {" +
                "  mutating private func bar() {} }")
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["acl",
                                                                    "typeMethods",
                                                                    "owned",
                                                                    "setterACL",
                                                                    "final",
                                                                    "mutators",
                                                                    "override"]])
    }

    //swiftlint:disable function_body_length
    func testAtPrefixedGroup() {
        let descriptionOverride = RuleDescription(
            identifier: "modifier_order",
            name: "Modifier Order",
            description: "Modifier order should be consistent.",
            kind: .style,
            minSwiftVersion: .fourDotOne,
            nonTriggeringExamples: [
                Example("class Foo { \n"                                        +
                "   @objc \n"                                           +
                "   internal var bar: String {\n"                       +
                "       return \"foo\"\n"                               +
                "   }\n"                                                +
                "} \n"                                                  +
                "class Bar: Foo { \n"                                   +
                "   @objc \n"                                           +
                "   override internal var bar: String { \n"             +
                "       return \"bar\"\n"                               +
                "   }\n"                                                +
                "}"),
                Example("@objcMembers \n"                                       +
                "public final class Bar {} \n"),
                Example("class Foo { \n"                                        +
                "   @IBOutlet internal weak var bar: UIView!\n"         +
                "}"),
                Example("class Foo { \n"                                        +
                "   @IBAction internal func bar() {}\n"                 +
                "}\n"                                                   +
                "class Bar: Foo { \n"                                   +
                "   @IBAction override internal func bar() {}\n"        +
                "}"),
                Example("public class Foo {\n"                                  +
                "   @NSCopying public final var foo:NSString = \"s\"\n" +
                "}"),
                Example("public class Bar {\n"                                  +
                "   @NSManaged public final var foo: NSString \n"       +
                "}\n")
            ],
            triggeringExamples: [
                Example("class Foo { \n"                                        +
                "   @objc \n"                                           +
                "   internal var bar: String {\n"                       +
                "       return \"foo\"\n"                               +
                "   }\n"                                                +
                "} \n"                                                  +
                "class Bar: Foo { \n"                                   +
                "   @objc \n"                                           +
                "   internal override var bar: String { \n"             +
                "       return \"bar\"\n"                               +
                "   }\n"                                                +
                "}"),
                Example("@objcMembers \n"                                       +
                "final public class Bar {} \n"),
                Example("class Foo { \n"                                        +
                "   @IBOutlet weak internal var bar: UIView!\n"         +
                "}"),
                Example("class Foo { \n"                                        +
                "   @IBAction internal func bar() {}\n"                 +
                "}\n"                                                   +
                "class Bar: Foo { \n"                                   +
                "   @IBAction internal override func bar() {}\n"        +
                "}"),
                Example("public class Foo {\n"                                  +
                "   @NSCopying final public var foo:NSString = \"s\"\n" +
                "}"),
                Example("public class Bar {\n"                                  +
                "   @NSManaged final public var foo: NSString \n"       +
                "}\n")
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["override", "acl", "owned", "final"]])
    }

    func testNonSpecifiedModifiersDontInterfere() {
        let descriptionOverride = RuleDescription(
            identifier: "modifier_order",
            name: "Modifier Order",
            description: "Modifier order should be consistent.",
            kind: .style,
            minSwiftVersion: .fourDotOne,
            nonTriggeringExamples: [
                Example("""
                class Foo {
                    weak final override private var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    final weak override private var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    final override weak private var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    final override private weak var bar: UIView?
                }
                """)
            ],
            triggeringExamples: [
                Example("""
                class Foo {
                    weak override final private var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    override weak final private var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    override final weak private var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    override final private weak var bar: UIView?
                }
                """)
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl"]])
    }

    func testCorrectionsAreAppliedCorrectly() {
        let descriptionOverride = RuleDescription(
            identifier: "modifier_order",
            name: "Modifier Order",
            description: "Modifier order should be consistent.",
            kind: .style,
            minSwiftVersion: .fourDotOne,
            nonTriggeringExamples: [],
            triggeringExamples: [],
            corrections: [
                Example("""
                class Foo {
                    private final override var bar: UIView?
                }
                """):
                Example("""
                class Foo {
                    final override private var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    private final var bar: UIView?
                }
                """):
                Example("""
                class Foo {
                    final private var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    class private final var bar: UIView?
                }
                """):
                Example("""
                class Foo {
                    final private class var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    @objc
                    private
                    class
                    final
                    override
                    var bar: UIView?
                }
                """):
                Example("""
                class Foo {
                    @objc
                    final
                    override
                    private
                    class
                    var bar: UIView?
                }
                """),
                Example("""
                private final class Foo {}
                """):
                Example("""
                final private class Foo {}
                """)
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl", "typeMethods"]])
    }

    func testCorrectionsAreNotAppliedToIrrelevantModifier() {
        let descriptionOverride = RuleDescription(
            identifier: "modifier_order",
            name: "Modifier Order",
            description: "Modifier order should be consistent.",
            kind: .style,
            minSwiftVersion: .fourDotOne,
            nonTriggeringExamples: [],
            triggeringExamples: [],
            corrections: [
                Example("""
                class Foo {
                    weak class final var bar: UIView?
                }
                """):
                Example("""
                class Foo {
                    weak final class var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    static weak final var bar: UIView?
                }
                """):
                Example("""
                class Foo {
                    final weak static var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    class final weak var bar: UIView?
                }
                """):
                Example("""
                class Foo {
                    final class weak var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    @objc
                    private
                    private(set)
                    class
                    final
                    var bar: UIView?
                }
                """):
                Example("""
                class Foo {
                    @objc
                    final
                    private(set)
                    private
                    class
                    var bar: UIView?
                }
                """),
                Example("""
                class Foo {
                    var bar: UIView?
                }
                """):
                Example("""
                class Foo {
                    var bar: UIView?
                }
                """)
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl", "typeMethods"]])
    }

    func testTypeMethodClassCorrection() {
        let descriptionOverride = RuleDescription(
            identifier: "modifier_order",
            name: "Modifier Order",
            description: "Modifier order should be consistent.",
            kind: .style,
            minSwiftVersion: .fourDotOne,
            nonTriggeringExamples: [],
            triggeringExamples: [],
            corrections: [
                Example("""
                private final class Foo {}
                """):
                Example("""
                final private class Foo {}
                """),
                Example("""
                public protocol Foo: class {}\n
                """):
                Example("""
                public protocol Foo: class {}\n
                """)
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "typeMethods", "acl"]])
    }

    func testViolationMessage() {
        guard SwiftVersion.current >= ModifierOrderRule.description.minSwiftVersion else {
            return
        }

        let ruleID = ModifierOrderRule.description.identifier
        guard let config = makeConfig(["preferred_modifier_order": ["acl", "final"]], ruleID) else {
            XCTFail("Failed to create configuration")
            return
        }

        let allViolations = violations(Example("final public var foo: String"), config: config)
        let modifierOrderRuleViolation = allViolations.first { $0.ruleIdentifier == ruleID }
        if let violation = modifierOrderRuleViolation {
            XCTAssertEqual(violation.reason, "public modifier should be before final.")
        } else {
            XCTFail("A modifier order violation should have been triggered!")
        }
    }
}
