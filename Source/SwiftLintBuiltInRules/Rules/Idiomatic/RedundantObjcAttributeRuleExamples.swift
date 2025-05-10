struct RedundantObjcAttributeRuleExamples {
    static let nonTriggeringExamples = [
        Example("@objc private var foo: String? {}"),
        Example("@IBInspectable private var foo: String? {}"),
        Example("@objc private func foo(_ sender: Any) {}"),
        Example("@IBAction private func foo(_ sender: Any) {}"),
        Example("@GKInspectable private var foo: String! {}"),
        Example("private @GKInspectable var foo: String! {}"),
        Example("@NSManaged var foo: String!"),
        Example("@objc @NSCopying var foo: String!"),
        Example("""
        @objcMembers
        class Foo {
            var bar: Any?
            @objc
            class Bar: NSObject {
                @objc
                var foo: Any?
            }
        }
        """),
        Example("""
        @objc
        extension Foo {
            var bar: Int {
                return 0
            }
        }
        """),
        Example("""
        extension Foo {
            @objc
            var bar: Int { return 0 }
        }
        """),
        Example("""
        @objc @IBDesignable
        extension Foo {
            var bar: Int { return 0 }
        }
        """),
        Example("""
        @IBDesignable
        extension Foo {
            @objc
            var bar: Int { return 0 }
            var fooBar: Int { return 1 }
        }
        """),
        Example("""
        @objcMembers
        class Foo: NSObject {
            @objc
            private var bar: Int {
                return 0
            }
        }
        """),
        Example("""
        @objcMembers
        class Foo {
            @objc
            class Bar: NSObject {
                @objc var foo: Any?
            }
        }
        """),
        Example("""
        @objcMembers
        class Foo: NSObject {
            @objc class Bar {}
        }
        """),
        Example("""
        extension BlockEditorSettings {
            @objc(addElementsObject:)
            @NSManaged public func addToElements(_ value: BlockEditorSettingElement)
        }
        """),
        Example("""
        @objcMembers
        public class Foo: NSObject {
            @objc
            private func handler(_ notification: Notification) {
            }

            func registerForNotifications() {
                NotificationCenter.default.addObserver(self, selector: #selector(handler(_:)), name: nil, object: nil)
            }
        }
        """),
        Example("""
        class Foo: NSObject { }

        @objc extension Foo {
            @objc enum Bar: Int {
               case bar
            }

            var bar: Bar { .bar }
        }
        """),
        Example("""
        class Foo: NSObject { }

        @objc extension Foo {
            @objc private enum Baz: Int {
              case baz
            }

            private var baz: Baz { .baz }
        }
        """),
        Example("""
        @objcMembers
        internal class Foo: NSObject {
            @objc
            private var baz: Int = 1

            var x: Any? {
                value(forKey: "baz")
            }
        }
        """),
        Example("""
        @objcMembers
        class Foo: NSObject {
            @objc enum Bar: Int {
               case bar
            }
        }
        """),
    ]

    static let triggeringExamples = [
        Example("↓@objc @IBInspectable private var foo: String? {}"),
        Example("@IBInspectable ↓@objc private var foo: String? {}"),
        Example("↓@objc @IBAction private func foo(_ sender: Any) {}"),
        Example("@IBAction ↓@objc private func foo(_ sender: Any) {}"),
        Example("↓@objc @GKInspectable private var foo: String! {}"),
        Example("@GKInspectable ↓@objc private var foo: String! {}"),
        Example("↓@objc @NSManaged private var foo: String!"),
        Example("@NSManaged ↓@objc private var foo: String!"),
        Example("↓@objc @IBDesignable class Foo {}"),
        Example("""
        @objcMembers
        class Foo: NSObject {
            ↓@objc var bar: Any?
        }
        """),
        Example("""
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
        """),
        Example("""
        @objc
        extension Foo {
            ↓@objc
            var bar: Int {
                return 0
            }
        }
        """),
        Example("""
        @objc @IBDesignable
        extension Foo {
            ↓@objc
            var bar: Int {
                return 0
            }
        }
        """),
        Example("""
        @objcMembers
        class Foo: NSObject {
            @objcMembers
            class Bar: NSObject {
                ↓@objc var foo: Any
            }
        }
        """),
        Example("""
        @objc
        extension Foo {
            ↓@objc
            private var bar: Int {
                return 0
            }
        }
        """),
    ]

    static let corrections = [
        Example("↓@objc @IBInspectable private var foo: String? {}"):
            Example("@IBInspectable private var foo: String? {}"),
        Example("@IBInspectable ↓@objc private var foo: String? {}"):
            Example("@IBInspectable private var foo: String? {}"),
        Example("@IBAction ↓@objc private func foo(_ sender: Any) {}"):
            Example("@IBAction private func foo(_ sender: Any) {}"),
        Example("↓@objc @GKInspectable private var foo: String! {}"):
            Example("@GKInspectable private var foo: String! {}"),
        Example("@GKInspectable ↓@objc private var foo: String! {}"):
            Example("@GKInspectable private var foo: String! {}"),
        Example("↓@objc @NSManaged private var foo: String!"): Example("@NSManaged private var foo: String!"),
        Example("@NSManaged ↓@objc private var foo: String!"): Example("@NSManaged private var foo: String!"),
        Example("↓@objc @IBDesignable class Foo {}"): Example("@IBDesignable class Foo {}"),
        Example("""
        @objcMembers
        class Foo: NSObject {
            ↓@objc var bar: Any?
        }
        """):
        Example("""
        @objcMembers
        class Foo: NSObject {
            var bar: Any?
        }
        """),
        Example("""
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
        """):
        Example("""
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
        """),
        Example("""
        @objc
        extension Foo {
            ↓@objc
            var bar: Int {
                return 0
            }
        }
        """):
        Example("""
        @objc
        extension Foo {
            var bar: Int {
                return 0
            }
        }
        """),
        Example("""
        @objc @IBDesignable
        extension Foo {
            ↓@objc
            var bar: Int {
                return 0
            }
        }
        """):
        Example("""
        @objc @IBDesignable
        extension Foo {
            var bar: Int {
                return 0
            }
        }
        """),
        Example("""
        @objcMembers
        class Foo: NSObject {
            @objcMembers
            class Bar: NSObject {
                ↓@objc var foo: Any
            }
        }
        """):
        Example("""
        @objcMembers
        class Foo: NSObject {
            @objcMembers
            class Bar: NSObject {
                var foo: Any
            }
        }
        """),
        Example("""
        @objc
        extension Foo {
            ↓@objc
            private var bar: Int {
                return 0
            }
        }
        """):
        Example("""
        @objc
        extension Foo {
            private var bar: Int {
                return 0
            }
        }
        """),
        Example("""
        @objc
        extension Foo {
            ↓@objc


            private var bar: Int {
                return 0
            }
        }
        """):
        Example("""
        @objc
        extension Foo {
            private var bar: Int {
                return 0
            }
        }
        """),
    ]
}
