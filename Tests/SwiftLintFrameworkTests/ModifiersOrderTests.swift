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
            nonTriggeringExamples: [
                "public class SomeClass { \n" +
                    "    static public func someFunc() {} \n" +
                "}"
            ],
            triggeringExamples: [
                "public class SomeClass { \n" +
                    "    public static func someFunc() {} \n" +
                "}"
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["before_acl": ["static"]])
    }

    func testAttibuteClass() {
        // testing class as attribute position
        let descriptionOverride = RuleDescription(
            identifier: "modifiers_order",
            name: "Modifiers Order",
            description: "Modifiers order should be consistent.",
            nonTriggeringExamples: [
                "public class SomeClass { \n" +
                    "    class public func someFunc() {} \n" +
                "}"
            ],
            triggeringExamples: [
                "public class SomeClass { \n" +
                    "    public class func someFunc() {} \n" +
                "}"
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["before_acl": ["class"]])
    }

    func testAttributesOrderLeft() {
        // testing override position
        let descriptionOverride = RuleDescription(
            identifier: "modifiers_order",
            name: "Modifiers Order",
            description: "Modifiers order should be consistent.",
            nonTriggeringExamples: [
                "class RootClass { func myFinal() {}}\n" +
                    "internal class MyClass: RootClass {" +
                "override internal func myFinal() {}}"
            ],
            triggeringExamples: [
                "public class RootClass { public func myFinal() {}}\n" +
                    "public class MyClass: RootClass {" +
                "public override func myFinal() {}}"
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["before_acl": ["override"]])
    }
}
