internal struct AttributesRuleExamples {
    static let nonTriggeringExamples = [
        Example("@objc var x: String"),
        Example("@objc private var x: String"),
        Example("@nonobjc var x: String"),
        Example("@IBOutlet private var label: UILabel"),
        Example("@IBOutlet @objc private var label: UILabel"),
        Example("@NSCopying var name: NSString"),
        Example("@NSManaged var name: String?"),
        Example("@IBInspectable var cornerRadius: CGFloat"),
        Example("@available(iOS 9.0, *)\n let stackView: UIStackView"),
        Example("@NSManaged func addSomeObject(book: SomeObject)"),
        Example("@IBAction func buttonPressed(button: UIButton)"),
        Example("@objc\n @IBAction func buttonPressed(button: UIButton)"),
        Example("@available(iOS 9.0, *)\n func animate(view: UIStackView)"),
        Example("@available(iOS 9.0, *, message=\"A message\")\n func animate(view: UIStackView)"),
        Example("@nonobjc\n final class X"),
        Example("@available(iOS 9.0, *)\n class UIStackView"),
        Example("@NSApplicationMain\n class AppDelegate: NSObject, NSApplicationDelegate"),
        Example("@UIApplicationMain\n class AppDelegate: NSObject, UIApplicationDelegate"),
        Example("@IBDesignable\n class MyCustomView: UIView"),
        Example("@testable import SourceKittenFramework"),
        Example("@objc(foo_x)\n var x: String"),
        Example("@available(iOS 9.0, *)\n@objc(abc_stackView)\n let stackView: UIStackView"),
        Example("@objc(abc_addSomeObject:)\n @NSManaged func addSomeObject(book: SomeObject)"),
        Example("@objc(ABCThing)\n @available(iOS 9.0, *)\n class Thing"),
        Example("class Foo: NSObject {\n override var description: String { return \"\" }\n}"),
        Example("class Foo: NSObject {\n\n override func setUp() {}\n}"),
        Example("@objc\nclass ⽺ {}\n"),

        // attribute with allowed empty new line above
        Example("extension Property {\n\n @available(*, unavailable, renamed: \"isOptional\")\n" +
        "public var optional: Bool { fatalError() }\n}"),
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
        """
    ]

    static let triggeringExamples = [
        Example("@objc\n ↓var x: String"),
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
