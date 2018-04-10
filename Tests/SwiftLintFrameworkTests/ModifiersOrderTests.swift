//
//  ModifiersOrderTests.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 06/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class ModifiersOrderTests: XCTestCase {

    func testAttibuteStatic() {
        // testing static attribute position
        let descriptionOverride = RuleDescription(
            identifier: "modifiers_order",
            name: "Modifiers Order",
            description: "Modifiers order should be consistent.",
            kind: .style,
            nonTriggeringExamples: [
                "public class SomeClass { \n" +
                    "    static public func someFunc() {} \n" +
                "}",
                "public class SomeClass { \n" +
                    "    class public func someFunc() {} \n" +
                "}"
            ],
            triggeringExamples: [
                "public class SomeClass { \n" +
                    "    public static func someFunc() {} \n" +
                "}",
                "public class SomeClass { \n" +
                    "    public class func someFunc() {} \n" +
                "}"
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["prefered_modifiers_order": ["typeMethods", "acl"]])
    }

    func testRightOrderedModifierGroups() {
        // testing modifiers ordered to the right from the ACL
        let descriptionOverride = RuleDescription(
            identifier: "modifiers_order",
            name: "Modifiers Order",
            description: "Modifiers order should be consistent.",
            kind: .style,
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
                   ruleConfiguration: ["prefered_modifiers_order": ["acl",
                                                                    "typeMethods",
                                                                    "owned",
                                                                    "setterACL",
                                                                    "final",
                                                                    "mutators",
                                                                    "override"]])
    }
}
