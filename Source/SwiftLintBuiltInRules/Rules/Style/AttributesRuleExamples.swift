internal struct AttributesRuleExamples {
    static let nonTriggeringExamples = #examples([
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
        "@available(*, deprecated, message: \"A message\")\n func animate(view: UIStackView)",
        "@nonobjc\n final class X {}",
        "@available(iOS 9.0, *)\n class UIStackView {}",
        "@NSApplicationMain\n class AppDelegate: NSObject, NSApplicationDelegate {}",
        "@UIApplicationMain\n class AppDelegate: NSObject, UIApplicationDelegate {}",
        "@IBDesignable\n class MyCustomView: UIView {}",
        "@testable import SourceKittenFramework",
        "@objc(foo_x)\n var x: String",
        "@available(iOS 9.0, *)\n@objc(abc_stackView)\n let stackView: UIStackView",
        "@objc(abc_addSomeObject:)\n @NSManaged func addSomeObject(book: SomeObject)",
        "@objc(ABCThing)\n @available(iOS 9.0, *)\n class Thing {}",
        "class Foo: NSObject {\n override var description: String { return \"\" }\n}",
        "class Foo: NSObject {\n\n override func setUp() {}\n}",
        "@objc\nclass ⽺ {}",

        // attribute with allowed empty new line above
        """
        extension Property {

            @available(*, unavailable, renamed: \"isOptional\")
            public var optional: Bool { fatalError() }
        }
        """,
        "@GKInspectable var maxSpeed: Float",
        "@discardableResult\n func a() -> Int",
        "@objc\n @discardableResult\n func a() -> Int",
        "func increase(f: @autoclosure () -> Int) -> Int",
        "func foo(completionHandler: @escaping () -> Void)",
        "private struct DefaultError: Error {}",
        "@testable import foo\n\nprivate let bar = 1",
        """
        import XCTest
        @testable import DeleteMe

        @available (iOS 11.0, *)
        class DeleteMeTests: XCTestCase {
        }
        """,
        """
        @objc
        internal func foo(identifier: String, completion: @escaping (() -> Void)) {}
        """,
        """
        @objc
        internal func foo(identifier: String, completion: @autoclosure (() -> Bool)) {}
        """,
        """
        func printBoolOrTrue(_ expression: @autoclosure () throws -> Bool?) rethrows {
          try print(expression() ?? true)
        }
        """,
        """
        import Foundation

        class MyClass: NSObject {
          @objc(
            first:
          )
          static func foo(first: String) {}
        }
        """,
        """
        func refreshable(action: @escaping @Sendable () async -> Void) -> some View {
            modifier(RefreshableModifier(action: action))
        }
        """,
        """
        import AppKit

        @NSApplicationMain
        @MainActor
        final class AppDelegate: NSAppDelegate {}
        """,
        #"""
        @_spi(Private) import SomeFramework

        @_spi(Private)
        final class MyView: View {
            @SwiftUI.Environment(\.colorScheme) var first: ColorScheme
            @Environment(\.colorScheme) var second: ColorScheme
            @Persisted(primaryKey: true) var id: Int
        }
        """#.configuration(["attributes_with_arguments_always_on_line_above": false]).excludeFromDocumentation(),
    ])

    static let triggeringExamples = #examples([
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
        "@nonobjc final ↓class X {}",
        "@available(iOS 9.0, *) ↓class UIStackView {}",
        "@available(iOS 9.0, *)\n @objc ↓class UIStackView {}",
        "@available(iOS 9.0, *) @objc\n ↓class UIStackView {}",
        "@available(iOS 9.0, *)\n\n ↓class UIStackView {}",
        "@UIApplicationMain ↓class AppDelegate: NSObject, UIApplicationDelegate {}",
        "@IBDesignable ↓class MyCustomView: UIView {}",
        "@testable\n↓import SourceKittenFramework",
        "@testable\n\n\n↓import SourceKittenFramework",
        "@available(iOS 9.0, *) @objc(abc_stackView)\n ↓let stackView: UIStackView",
        "@objc(abc_addSomeObject:) @NSManaged\n ↓func addSomeObject(book: SomeObject)",
        "@objc(abc_addSomeObject:)\n @NSManaged\n ↓func addSomeObject(book: SomeObject)",
        "@available(iOS 9.0, *)\n @objc(ABCThing) ↓class Thing {}",
        "@GKInspectable\n ↓var maxSpeed: Float",
        "@discardableResult ↓func a() -> Int",
        "@objc\n @discardableResult ↓func a() -> Int",
        "@objc\n\n @discardableResult\n ↓func a() -> Int",
        #"""
        struct S: View {
            @Environment(\.colorScheme) ↓var first: ColorScheme
            @Persisted var id: Int
            @FetchRequest(
                  animation: nil
            )
            var entities: FetchedResults
        }
        """#.excludeFromDocumentation(),
    ])
}
