internal struct ModifierOrderRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
        public class Foo {
           public required convenience init() {}
        }
        """,
        """
        public class Foo {
           public static let bar = 42
        }
        """,
        """
        public class Foo {
           public static var bar: Int {
               return
           }
        }
        """,
        """
        public class Foo {
           public class var bar: Int {
               return 42
           }
        }
        """,
        """
        public class Bar {
           public class var foo: String {
               return "foo"
           }
        }
        public class Foo: Bar {
           override public final class var foo: String {
               return "bar"
           }
        }
        """,
        """
        open class Bar {
           public var foo: Int? {
               return 42
           }
        }
        open class Foo: Bar {
           override public var foo: Int? {
               return 43
           }
        }
        """,
        """
        open class Bar {
           open class func foo() -> Int {
               return 42
           }
        }
        class Foo: Bar {
           override open class func foo() -> Int {
               return 43
           }
        }
        """,
        """
        protocol Foo: class {}
        class Bar {
            public private(set) weak var foo: Foo?
        }
        """,
        """
        @objc
        public final class Foo: NSObject {}
        """,
        """
        @objcMembers
        public final class Foo: NSObject {}
        """,
        """
        @objc
        override public private(set) weak var foo: Bar?
        """,
        """
        @objc
        public final class Foo: NSObject {}
        """,
        """
        @objc
        open final class Foo: NSObject {
           open weak var weakBar: NSString? = nil
        }
        """,
        """
        public final class Foo {}
        """,
        """
        class Bar {
           func bar() {}
        }
        """,
        """
        internal class Foo: Bar {
           override internal func bar() {}
        }
        """,
        """
        public struct Foo {
           internal weak var weakBar: NSObject? = nil
        }
        """,
        """
        class Foo {
           internal lazy var bar: String = "foo"
        }
        """,
    ])

    static let triggeringExamples = #examples([
        """
        class Foo {
           convenience required public init() {}
        }
        """,
        """
        public class Foo {
           static public let bar = 42
        }
        """,
        """
        public class Foo {
           static public var bar: Int {
               return 42
           }
        }
        """,
        """
        public class Foo {
           class public var bar: Int {
               return 42
           }
        }
        """,
        """
        public class RootFoo {
           class public var foo: String {
               return "foo"
           }
        }
        public class Foo: RootFoo {
           override final class public var foo: String
               return "bar"
           }
        }
        """,
        """
        open class Bar {
           public var foo: Int? {
               return 42
           }
        }
        open class Foo: Bar {
            public override var foo: Int? {
               return 43
           }
        }
        """,
        """
        protocol Foo: class {}
            class Bar {
                private(set) public weak var foo: Foo?
        }
        """,
        """
        open class Bar {
           open class func foo() -> Int {
               return 42
           }
        }
        class Foo: Bar {
           class open override func foo() -> Int {
               return 43
           }
        }
        """,
        """
        open class Bar {
           open class func foo() -> Int {
               return 42
           }
        }
        class Foo: Bar {
           open override class func foo() -> Int {
               return 43
           }
        }
        """,
        """
        @objc
        final public class Foo: NSObject {}
        """,
        """
        @objcMembers
        final public class Foo: NSObject {}
        """,
        """
        @objc
        final open class Foo: NSObject {
           weak open var weakBar: NSString? = nil
        }
        """,
        """
        final public class Foo {}
        """,
        """
        internal class Foo: Bar {
           internal override func bar() {}
        }
        """,
        """
        public struct Foo {
           weak internal var weakBar: NSObjetc? = nil
        }
        """,
        """
        class Foo {
           lazy internal var bar: String = "foo"
        }
        """,
    ])
}
