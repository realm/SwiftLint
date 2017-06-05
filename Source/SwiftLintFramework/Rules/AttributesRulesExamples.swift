//
//  AttributesRulesExamples.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/09/16.
//  Copyright © 2016 Realm. All rights reserved.
//

internal struct AttributesRuleExamples {

    static let nonTriggeringExamples = [
        "@objc var x: String",
        "@objc private var x: String",
        "@nonobjc var x: String",
        "@IBOutlet private var label: UILabel",
        "@IBOutlet @objc private var label: UILabel",
        "@NSCopying var name: NSString",
        "@NSManaged var name: String?",
        "@IBInspectable var cornerRadius: CGFloat",
        "@available(iOS 9.0, *)\n let stackView: UIStackView",
        "@NSManaged func addSomeObject(book: SomeObject)",
        "@IBAction func buttonPressed(button: UIButton)",
        "@objc\n @IBAction func buttonPressed(button: UIButton)",
        "@available(iOS 9.0, *)\n func animate(view: UIStackView)",
        "@available(iOS 9.0, *, message=\"A message\")\n func animate(view: UIStackView)",
        "@nonobjc\n final class X",
        "@available(iOS 9.0, *)\n class UIStackView",
        "@NSApplicationMain\n class AppDelegate: NSObject, NSApplicationDelegate",
        "@UIApplicationMain\n class AppDelegate: NSObject, UIApplicationDelegate",
        "@IBDesignable\n class MyCustomView: UIView",
        "@testable import SourceKittenFramework",
        "@objc(foo_x)\n var x: String",
        "@available(iOS 9.0, *)\n@objc(abc_stackView)\n let stackView: UIStackView",
        "@objc(abc_addSomeObject:)\n @NSManaged func addSomeObject(book: SomeObject)",
        "@objc(ABCThing)\n @available(iOS 9.0, *)\n class Thing",
        "class Foo: NSObject {\n override var description: String { return \"\" }\n}",
        "class Foo: NSObject {\n\n override func setUp() {}\n}",
        "@objc\nclass ⽺ {}\n",

        // attribute with allowed empty new line above
        "extension Property {\n\n @available(*, unavailable, renamed: \"isOptional\")\n" +
        "public var optional: Bool { fatalError() }\n}",
        "@GKInspectable var maxSpeed: Float",
        "@discardableResult\n func a() -> Int",
        "@objc\n @discardableResult\n func a() -> Int",
        "func increase(f: @autoclosure () -> Int) -> Int",
        "func foo(completionHandler: @escaping () -> Void)"
    ]

    static let triggeringExamples = [
        "@objc\n ↓var x: String",
        "@objc\n\n ↓var x: String",
        "@objc\n private ↓var x: String",
        "@nonobjc\n ↓var x: String",
        "@IBOutlet\n private ↓var label: UILabel",
        "@IBOutlet\n\n private ↓var label: UILabel",
        "@NSCopying\n ↓var name: NSString",
        "@NSManaged\n ↓var name: String?",
        "@IBInspectable\n ↓var cornerRadius: CGFloat",
        "@available(iOS 9.0, *) ↓let stackView: UIStackView",
        "@NSManaged\n ↓func addSomeObject(book: SomeObject)",
        "@IBAction\n ↓func buttonPressed(button: UIButton)",
        "@IBAction\n @objc\n ↓func buttonPressed(button: UIButton)",
        "@available(iOS 9.0, *) ↓func animate(view: UIStackView)",
        "@nonobjc final ↓class X",
        "@available(iOS 9.0, *) ↓class UIStackView",
        "@available(iOS 9.0, *)\n @objc ↓class UIStackView",
        "@available(iOS 9.0, *) @objc\n ↓class UIStackView",
        "@available(iOS 9.0, *)\n\n ↓class UIStackView",
        "@UIApplicationMain ↓class AppDelegate: NSObject, UIApplicationDelegate",
        "@IBDesignable ↓class MyCustomView: UIView",
        "@testable\n↓import SourceKittenFramework",
        "@testable\n\n\n↓import SourceKittenFramework",
        "@objc(foo_x) ↓var x: String",
        "@available(iOS 9.0, *) @objc(abc_stackView)\n ↓let stackView: UIStackView",
        "@objc(abc_addSomeObject:) @NSManaged\n ↓func addSomeObject(book: SomeObject)",
        "@objc(abc_addSomeObject:)\n @NSManaged\n ↓func addSomeObject(book: SomeObject)",
        "@available(iOS 9.0, *)\n @objc(ABCThing) ↓class Thing",
        "@GKInspectable\n ↓var maxSpeed: Float",
        "@discardableResult ↓func a() -> Int",
        "@objc\n @discardableResult ↓func a() -> Int",
        "@objc\n\n @discardableResult\n ↓func a() -> Int"
    ]
}
