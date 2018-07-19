@testable import SwiftLintFramework
import XCTest

class ModifierOrderTests: XCTestCase {

    func testAttributeTypeMethod() {
        let descriptionOverride = RuleDescription(
            identifier: "modifier_order",
            name: "Modifier Order",
            description: "Modifier order should be consistent.",
            kind: .style,
            minSwiftVersion: .fourDotOne,
            nonTriggeringExamples: [
                "public class SomeClass { \n" +
                "   class public func someFunc() {} \n" +
                "}",
                "public class SomeClass { \n" +
                "   static public func someFunc() {} \n" +
                "}"
            ],
            triggeringExamples: [
                "public class SomeClass { \n" +
                "   public class func someFunc() {} \n" +
                "}",
                "public class SomeClass { \n" +
                "   public static func someFunc() {} \n" +
                "}"
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
                "public protocol Foo: class {}\n" +
                "public weak internal(set) var bar: Foo? \n",
                "open final class Foo {" +
                "  fileprivate static  func bar() {} \n" +
                "  open class func barFoo() {} }",
                "public struct Foo {" +
                "  private mutating func bar() {} }"
            ],
            triggeringExamples: [
                "public protocol Foo: class {} \n" +
                "public internal(set) weak var bar: Foo? \n",
                "final public class Foo {" +
                "  static fileprivate func bar() {} \n" +
                "  class open func barFoo() {} }",
                "public struct Foo {" +
                "  mutating private func bar() {} }"
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
                "class Foo { \n"                                        +
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
                "}",
                "@objcMembers \n"                                       +
                "public final class Bar {} \n",
                "class Foo { \n"                                        +
                "   @IBOutlet internal weak var bar: UIView!\n"         +
                "}",
                "class Foo { \n"                                        +
                "   @IBAction internal func bar() {}\n"                 +
                "}\n"                                                   +
                "class Bar: Foo { \n"                                   +
                "   @IBAction override internal func bar() {}\n"        +
                "}",
                "public class Foo {\n"                                  +
                "   @NSCopying public final var foo:NSString = \"s\"\n" +
                "}",
                "public class Bar {\n"                                  +
                "   @NSManaged public final var foo: NSString \n"       +
                "}\n"
            ],
            triggeringExamples: [
                "class Foo { \n"                                        +
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
                "}",
                "@objcMembers \n"                                       +
                "final public class Bar {} \n",
                "class Foo { \n"                                        +
                "   @IBOutlet weak internal var bar: UIView!\n"         +
                "}",
                "class Foo { \n"                                        +
                "   @IBAction internal func bar() {}\n"                 +
                "}\n"                                                   +
                "class Bar: Foo { \n"                                   +
                "   @IBAction internal override func bar() {}\n"        +
                "}",
                "public class Foo {\n"                                  +
                "   @NSCopying final public var foo:NSString = \"s\"\n" +
                "}",
                "public class Bar {\n"                                  +
                "   @NSManaged final public var foo: NSString \n"       +
                "}\n"
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["override", "acl", "final"]])
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

        let allViolations = violations("final public var foo: String", config: config)
        let modifierOrderRuleViolation = allViolations.first { $0.ruleDescription.identifier == ruleID }
        if let violation = modifierOrderRuleViolation {
            XCTAssertEqual(violation.reason, "public modifier should be before final.")
        } else {
            XCTFail("A modifier order violation should have been triggered!")
        }
    }
}
