import SwiftLintCore

struct RedundantObjcAttributeRuleExamples {
    static let nonTriggeringExamples = #examples([
        "@objc private var foo: String? {}",
        "@IBInspectable private var foo: String? {}",
        "@objc private func foo(_ sender: Any) {}",
        "@IBAction private func foo(_ sender: Any) {}",
        "@GKInspectable private var foo: String! {}",
        "private @GKInspectable var foo: String! {}",
        "@NSManaged var foo: String!",
        "@objc @NSCopying var foo: String!",
        """
        @objcMembers
        class Foo {
            var bar: Any?
            @objc
            class Bar: NSObject {
                @objc
                var foo: Any?
            }
        }
        """,
        """
        @objc
        extension Foo {
            var bar: Int {
                return 0
            }
        }
        """,
        """
        extension Foo {
            @objc
            var bar: Int { return 0 }
        }
        """,
        """
        @objc @IBDesignable
        extension Foo {
            var bar: Int { return 0 }
        }
        """,
        """
        @IBDesignable
        extension Foo {
            @objc
            var bar: Int { return 0 }
            var fooBar: Int { return 1 }
        }
        """,
        """
        @objcMembers
        class Foo: NSObject {
            @objc
            private var bar: Int {
                return 0
            }
        }
        """,
        """
        @objcMembers
        class Foo {
            @objc
            class Bar: NSObject {
                @objc var foo: Any?
            }
        }
        """,
        """
        @objcMembers
        class Foo: NSObject {
            @objc class Bar {}
        }
        """,
        """
        extension BlockEditorSettings {
            @objc(addElementsObject:)
            @NSManaged public func addToElements(_ value: BlockEditorSettingElement)
        }
        """,
        """
        @objcMembers
        public class Foo: NSObject {
            @objc
            private func handler(_ notification: Notification) {
            }

            func registerForNotifications() {
                NotificationCenter.default.addObserver(self, selector: #selector(handler(_:)), name: nil, object: nil)
            }
        }
        """,
        """
        class Foo: NSObject { }

        @objc extension Foo {
            @objc enum Bar: Int {
               case bar
            }

            var bar: Bar { .bar }
        }
        """,
        """
        class Foo: NSObject { }

        @objc extension Foo {
            @objc private enum Baz: Int {
              case baz
            }

            private var baz: Baz { .baz }
        }
        """,
        """
        @objcMembers
        internal class Foo: NSObject {
            @objc
            private var baz: Int = 1

            var x: Any? {
                value(forKey: "baz")
            }
        }
        """,
        """
        @objcMembers
        class Foo: NSObject {
            @objc enum Bar: Int {
               case bar
            }
        }
        """,
    ])

    static let triggeringExamples = #examples([
        "↓@objc @IBInspectable private var foo: String? {}",
        "@IBInspectable ↓@objc private var foo: String? {}",
        "↓@objc @IBAction private func foo(_ sender: Any) {}",
        "@IBAction ↓@objc private func foo(_ sender: Any) {}",
        "↓@objc @GKInspectable private var foo: String! {}",
        "@GKInspectable ↓@objc private var foo: String! {}",
        "↓@objc @NSManaged private var foo: String!",
        "@NSManaged ↓@objc private var foo: String!",
        "↓@objc @IBDesignable class Foo {}",
        """
        @objcMembers
        class Foo: NSObject {
            ↓@objc var bar: Any?
        }
        """,
        """
        @objcMembers
        class Foo: NSObject {
            ↓@objc var bar: Any?
            ↓@objc var foo: Any?
            @objc
            class Bar {
                @objc
                var foo: Any?
            }
        }
        """,
        """
        @objc
        extension Foo {
            ↓@objc
            var bar: Int {
                return 0
            }
        }
        """,
        """
        @objc @IBDesignable
        extension Foo {
            ↓@objc
            var bar: Int {
                return 0
            }
        }
        """,
        """
        @objcMembers
        class Foo: NSObject {
            @objcMembers
            class Bar: NSObject {
                ↓@objc var foo: Any
            }
        }
        """,
        """
        @objc
        extension Foo {
            ↓@objc
            private var bar: Int {
                return 0
            }
        }
        """,
    ])

    static let corrections = #corrections([
        "↓@objc @IBInspectable private var foo: String? {}":
            "@IBInspectable private var foo: String? {}",
        "@IBInspectable ↓@objc private var foo: String? {}":
            "@IBInspectable private var foo: String? {}",
        "@IBAction ↓@objc private func foo(_ sender: Any) {}":
            "@IBAction private func foo(_ sender: Any) {}",
        "↓@objc @GKInspectable private var foo: String! {}":
            "@GKInspectable private var foo: String! {}",
        "@GKInspectable ↓@objc private var foo: String! {}":
            "@GKInspectable private var foo: String! {}",
        "↓@objc @NSManaged private var foo: String!": "@NSManaged private var foo: String!",
        "@NSManaged ↓@objc private var foo: String!": "@NSManaged private var foo: String!",
        "↓@objc @IBDesignable class Foo {}": "@IBDesignable class Foo {}",
        """
        @objcMembers
        class Foo: NSObject {
            ↓@objc var bar: Any?
        }
        """:
        """
        @objcMembers
        class Foo: NSObject {
            var bar: Any?
        }
        """,
        """
        @objcMembers
        class Foo: NSObject {
            ↓@objc var bar: Any?
            ↓@objc var foo: Any?
            @objc
            class Bar: NSObject {
                @objc
                var foo2: Any?
            }
        }
        """:
        """
        @objcMembers
        class Foo: NSObject {
            var bar: Any?
            var foo: Any?
            @objc
            class Bar: NSObject {
                @objc
                var foo2: Any?
            }
        }
        """,
        """
        @objc
        extension Foo {
            ↓@objc
            var bar: Int {
                return 0
            }
        }
        """:
        """
        @objc
        extension Foo {
            var bar: Int {
                return 0
            }
        }
        """,
        """
        @objc @IBDesignable
        extension Foo {
            ↓@objc
            var bar: Int {
                return 0
            }
        }
        """:
        """
        @objc @IBDesignable
        extension Foo {
            var bar: Int {
                return 0
            }
        }
        """,
        """
        @objcMembers
        class Foo: NSObject {
            @objcMembers
            class Bar: NSObject {
                ↓@objc var foo: Any
            }
        }
        """:
        """
        @objcMembers
        class Foo: NSObject {
            @objcMembers
            class Bar: NSObject {
                var foo: Any
            }
        }
        """,
        """
        @objc
        extension Foo {
            ↓@objc
            private var bar: Int {
                return 0
            }
        }
        """:
        """
        @objc
        extension Foo {
            private var bar: Int {
                return 0
            }
        }
        """,
        """
        @objc
        extension Foo {
            ↓@objc


            private var bar: Int {
                return 0
            }
        }
        """:
        """
        @objc
        extension Foo {
            private var bar: Int {
                return 0
            }
        }
        """,
    ])
}
