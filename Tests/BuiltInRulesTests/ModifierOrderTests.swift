import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

// swiftlint:disable file_length

@Suite(.rulesRegistered)
struct ModifierOrderTests { // swiftlint:disable:this type_body_length
    @Test
    func attributeTypeMethod() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: #examples([
                """
                public class SomeClass {
                   class public func someFunc() {}
                }
                """,
                """
                public class SomeClass {
                   static public func someFunc() {}
                }
                """,
            ]))
            .with(triggeringExamples: #examples([
                """
                public class SomeClass {
                   public class func someFunc() {}
                }
                """,
                """
                public class SomeClass {
                   public static func someFunc() {}
                }
                """,
            ]))
            .with(corrections: [:])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["typeMethods", "acl"]])
    }

    @Test
    func rightOrderedModifierGroups() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: #examples([
                "public protocol Foo: class {}\n" +
                "public weak internal(set) var bar: Foo? \n",
                "open final class Foo {" +
                "  fileprivate static  func bar() {} \n" +
                "  open class func barFoo() {} }",
                "public struct Foo {" +
                "  private mutating func bar() {} }",
            ]))
            .with(triggeringExamples: #examples([
                "public protocol Foo: class {} \n" +
                "public internal(set) weak var bar: Foo? \n",
                "final public class Foo {" +
                "  static fileprivate func bar() {} \n" +
                "  class open func barFoo() {} }",
                "public struct Foo {" +
                "  mutating private func bar() {} }",
            ]))
            .with(corrections: [:])

        verifyRule(
            descriptionOverride,
            ruleConfiguration: [
                "preferred_modifier_order": [
                    "acl",
                    "typeMethods",
                    "owned",
                    "setterACL",
                    "final",
                    "mutators",
                    "override",
                ],
            ]
        )
    }

    @Test
    func atPrefixedGroup() { // swiftlint:disable:this function_body_length
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: #examples([
                #"""
                class Foo {
                    @objc
                    internal var bar: String {
                       return "foo"
                    }
                }
                class Bar: Foo {
                   @objc
                   override internal var bar: String {
                       return "bar"
                   }
                }
                """#,
                """
                @objcMembers
                public final class Bar {}
                """,
                """
                class Foo {
                    @IBOutlet internal weak var bar: UIView!
                }
                """,
                """
                class Foo {
                    @IBAction internal func bar() {}
                }
                """,
                """
                class Bar: Foo {
                    @IBAction override internal func bar() {}
                }
                """,
                #"""
                public class Foo {
                   @NSCopying public final var foo:NSString = "s"
                }
                """#,
                #"""
                public class Foo {
                   @NSCopying public final var foo: NSString
                }
                """#,
            ]))
            .with(triggeringExamples: #examples([
                #"""
                class Foo {
                    @objc
                    internal var bar: String {
                       return "foo"
                    }
                }
                class Bar: Foo {
                   @objc
                    internal override var bar: String {
                       return "bar"
                   }
                }
                """#,
                """
                @objcMembers
                final public class Bar {}
                """,
                """
                class Foo {
                    @IBOutlet weak internal var bar: UIView!
                }
                """,
                """
                class Foo {
                    @IBAction internal func bar() {}
                }

                class Bar: Foo {
                    @IBAction internal override func bar() {}
                }
                """,
                #"""
                public class Foo {
                    @NSCopying final public var foo:NSString = "s"
                }
                """#,
                """
                public class Foo {
                    @NSManaged final public var foo: NSString
                }
                """,
            ]))
            .with(corrections: [:])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["override", "acl", "owned", "final"]])
    }

    @Test
    func nonSpecifiedModifiersDontInterfere() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: #examples([
                """
                class Foo {
                    weak final override private var bar: UIView?
                }
                """,
                """
                class Foo {
                    final weak override private var bar: UIView?
                }
                """,
                """
                class Foo {
                    final override weak private var bar: UIView?
                }
                """,
                """
                class Foo {
                    final override private weak var bar: UIView?
                }
                """,
            ]))
            .with(triggeringExamples: #examples([
                """
                class Foo {
                    weak override final private var bar: UIView?
                }
                """,
                """
                class Foo {
                    override weak final private var bar: UIView?
                }
                """,
                """
                class Foo {
                    override final weak private var bar: UIView?
                }
                """,
                """
                class Foo {
                    override final private weak var bar: UIView?
                }
                """,
            ]))
            .with(corrections: [:])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl"]])
    }

    @Test
    func correctionsAreAppliedCorrectly() { // swiftlint:disable:this function_body_length
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [], triggeringExamples: [])
            .with(corrections: #examplesDictionary([
                """
                class Foo {
                    private final override var bar: UIView?
                }
                """:
                """
                class Foo {
                    final override private var bar: UIView?
                }
                """,
                """
                class Foo {
                    private final var bar: UIView?
                }
                """:
                """
                class Foo {
                    final private var bar: UIView?
                }
                """,
                """
                class Foo {
                    class private final var bar: UIView?
                }
                """:
                """
                class Foo {
                    final private class var bar: UIView?
                }
                """,
                """
                class Foo {
                    @objc
                    private
                    class
                    final
                    override
                    var bar: UIView?
                }
                """:
                """
                class Foo {
                    @objc
                    final
                    override
                    private
                    class
                    var bar: UIView?
                }
                """,
                """
                private final class Foo {}
                """:
                """
                final private class Foo {}
                """,
            ]))

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl", "typeMethods"]])
    }

    @Test
    func correctionsAreNotAppliedToIrrelevantModifier() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [], triggeringExamples: [])
            .with(corrections: #examplesDictionary([
                """
                class Foo {
                    weak class final var bar: UIView?
                }
                """:
                """
                class Foo {
                    weak final class var bar: UIView?
                }
                """,
                """
                class Foo {
                    static weak final var bar: UIView?
                }
                """:
                """
                class Foo {
                    final static weak var bar: UIView?
                }
                """,
                """
                class Foo {
                    class final weak var bar: UIView?
                }
                """:
                """
                class Foo {
                    final class weak var bar: UIView?
                }
                """,
                """
                class Foo {
                    @objc
                    private private(set) class final var bar: UIView?
                }
                """:
                """
                class Foo {
                    @objc
                    final private private(set) class var bar: UIView?
                }
                """,
                """
                class Foo {
                    var bar: UIView?
                }
                """:
                """
                class Foo {
                    var bar: UIView?
                }
                """,
            ]))

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl", "typeMethods"]])
    }

    @Test
    func typeMethodClassCorrection() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [], triggeringExamples: [])
            .with(corrections: #examplesDictionary([
                """
                private final class Foo {}
                """:
                """
                final private class Foo {}
                """,
                """
                public protocol Foo: class {}\n
                """:
                """
                public protocol Foo: class {}\n
                """,
            ]))

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "typeMethods", "acl"]])
    }

    @Test
    func violationMessage() {
        let ruleID = ModifierOrderRule.identifier
        guard let config = makeConfig(["preferred_modifier_order": ["acl", "final"]], ruleID) else {
            Testing.Issue.record("Failed to create configuration")
            return
        }
        let allViolations = violations(Example("final public var foo: String"), config: config)
        let modifierOrderRuleViolation = allViolations.first { $0.ruleIdentifier == ruleID }
        if let violation = modifierOrderRuleViolation {
            #expect(violation.reason == "public modifier should come before final")
        } else {
            Testing.Issue.record("A modifier order violation should have been triggered!")
        }
    }

    @Test
    func isolationModifierOrder() { // swiftlint:disable:this function_body_length
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: #examples([
                """
                @MainActor
                class Foo {
                    nonisolated public func bar() {}
                }
                """,
                """
                actor MyActor: CustomStringConvertible {
                    nonisolated var description: String {
                        "MyActor instance"
                    }
                }
                """,
                """
                @MainActor
                class Foo {
                    isolated public func bar() {}
                }
                """,
                """
                class RegularClass {
                    @MainActor public func bar() {}
                }
                """,
            ]))
            .with(triggeringExamples: #examples([
                """
                @MainActor
                class Foo {
                    public nonisolated func bar() {}
                }
                """,
                """
                @MainActor
                class RegularClass {
                    private nonisolated func heavyWork() {}
                }
                """,
                """
                @MainActor
                class Foo {
                    public isolated func bar() {}
                }
                """,
            ]))
            .with(corrections: #examplesDictionary([
                """
                @MainActor
                class Foo {
                    public nonisolated func bar() {}
                }
                """:
                """
                @MainActor
                class Foo {
                    nonisolated public func bar() {}
                }
                """,
                """
                @MainActor
                class Foo {
                    public isolated func bar() {}
                }
                """:
                """
                @MainActor
                class Foo {
                    isolated public func bar() {}
                }
                """,
            ]))

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["override", "isolation", "acl", "final"]])
    }

    @Test
    func isolationModifierCustomOrder() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: #examples([
                """
                @MainActor
                class Foo {
                    public nonisolated final func bar() {}
                }
                """,
            ]))
            .with(triggeringExamples: #examples([
                """
                @MainActor
                class Foo {
                    nonisolated public func bar() {}
                }
                """,
            ]))
            .with(corrections: #examplesDictionary([
                """
                @MainActor
                class Foo {
                    nonisolated public func bar() {}
                }
                """:
                """
                @MainActor
                class Foo {
                    public nonisolated func bar() {}
                }
                """,
            ]))

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["override", "acl", "isolation", "final"]])
    }
}
