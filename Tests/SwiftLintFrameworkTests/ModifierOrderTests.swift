@testable import SwiftLintFramework
import XCTest

class ModifierOrderTests: XCTestCase {
    func testAttributeTypeMethod() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [
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
            ])
            .with(triggeringExamples: [
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
            ])
            .with(corrections: [:])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["typeMethods", "acl"]])
    }

    func testRightOrderedModifierGroups() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [
                Example("public protocol Foo: class {}\n" +
                "public weak internal(set) var bar: Foo? \n"),
                Example("open final class Foo {" +
                "  fileprivate static  func bar() {} \n" +
                "  open class func barFoo() {} }"),
                Example("public struct Foo {" +
                "  private mutating func bar() {} }")
            ])
            .with(triggeringExamples: [
                Example("public protocol Foo: class {} \n" +
                "public internal(set) weak var bar: Foo? \n"),
                Example("final public class Foo {" +
                "  static fileprivate func bar() {} \n" +
                "  class open func barFoo() {} }"),
                Example("public struct Foo {" +
                "  mutating private func bar() {} }")
            ])
            .with(corrections: [:])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["acl",
                                                                    "typeMethods",
                                                                    "owned",
                                                                    "setterACL",
                                                                    "final",
                                                                    "mutators",
                                                                    "override"]])
    }

    // swiftlint:disable:next function_body_length
    func testAtPrefixedGroup() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [
                Example(#"""
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
                """#),
                Example("""
                @objcMembers
                public final class Bar {}
                """),
                Example("""
                class Foo {
                    @IBOutlet internal weak var bar: UIView!
                }
                """),
                Example("""
                class Foo {
                    @IBAction internal func bar() {}
                }
                """),
                Example("""
                class Bar: Foo {
                    @IBAction override internal func bar() {}
                }
                """),
                Example(#"""
                public class Foo {
                   @NSCopying public final var foo:NSString = "s"
                }
                """#),
                Example(#"""
                public class Foo {
                   @NSCopying public final var foo: NSString
                }
                """#)
            ])
            .with(triggeringExamples: [
                Example(#"""
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
                """#),
                Example("""
                @objcMembers
                final public class Bar {}
                """),
                Example("""
                class Foo {
                    @IBOutlet weak internal var bar: UIView!
                }
                """),
                Example("""
                class Foo {
                    @IBAction internal func bar() {}
                }

                class Bar: Foo {
                    @IBAction internal override func bar() {}
                }
                """),
                Example(#"""
                public class Foo {
                    @NSCopying final public var foo:NSString = "s"
                }
                """#),
                Example("""
                public class Foo {
                    @NSManaged final public var foo: NSString
                }
                """)
            ])
            .with(corrections: [:])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["override", "acl", "owned", "final"]])
    }

    func testNonSpecifiedModifiersDontInterfere() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [
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
            ])
            .with(triggeringExamples: [
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
            ])
            .with(corrections: [:])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl"]])
    }

    // swiftlint:disable:next function_body_length
    func testCorrectionsAreAppliedCorrectly() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [], triggeringExamples: [])
            .with(corrections: [
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
            ])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl", "typeMethods"]])
    }

    // swiftlint:disable:next function_body_length
    func testCorrectionsAreNotAppliedToIrrelevantModifier() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [], triggeringExamples: [])
            .with(corrections: [
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
            ])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "override", "acl", "typeMethods"]])
    }

    func testTypeMethodClassCorrection() {
        let descriptionOverride = ModifierOrderRule.description
            .with(nonTriggeringExamples: [], triggeringExamples: [])
            .with(corrections: [
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
            ])

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["preferred_modifier_order": ["final", "typeMethods", "acl"]])
    }

    func testViolationMessage() {
        let ruleID = ModifierOrderRule.description.identifier
        guard let config = makeConfig(["preferred_modifier_order": ["acl", "final"]], ruleID) else {
            XCTFail("Failed to create configuration")
            return
        }

        let allViolations = violations(Example("final public var foo: String"), config: config)
        let modifierOrderRuleViolation = allViolations.first { $0.ruleIdentifier == ruleID }
        if let violation = modifierOrderRuleViolation {
            XCTAssertEqual(violation.reason, "public modifier should come before final")
        } else {
            XCTFail("A modifier order violation should have been triggered!")
        }
    }
}
