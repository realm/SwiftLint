internal struct ModifierOrderRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        public class Foo {
           public required convenience init() {}
        }
        """),
        Example("""
        public class Foo {
           public static let bar = 42
        }
        """),
        Example("""
        public class Foo {
           public static var bar: Int {
               return
           }
        }
        """),
        Example("""
        public class Foo {
           public class var bar: Int {
               return 42
           }
        }
        """),
        Example("""
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
        """),
        Example("""
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
        """),
        Example("""
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
        """),
        Example("""
        protocol Foo: class {}
        class Bar {
            public private(set) weak var foo: Foo?
        }
        """),
        Example("""
        @objc
        public final class Foo: NSObject {}
        """),
        Example("""
        @objcMembers
        public final class Foo: NSObject {}
        """),
        Example("""
        @objc
        override public private(set) weak var foo: Bar?
        """),
        Example("""
        @objc
        public final class Foo: NSObject {}
        """),
        Example("""
        @objc
        open final class Foo: NSObject {
           open weak var weakBar: NSString? = nil
        }
        """),
        Example("""
        public final class Foo {}
        """),
        Example("""
        class Bar {
           func bar() {}
        }
        """),
        Example("""
        internal class Foo: Bar {
           override internal func bar() {}
        }
        """),
        Example("""
        public struct Foo {
           internal weak var weakBar: NSObject? = nil
        }
        """),
        Example("""
        class Foo {
           internal lazy var bar: String = "foo"
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        class Foo {
           convenience required public init() {}
        }
        """),
        Example("""
        public class Foo {
           static public let bar = 42
        }
        """),
        Example("""
        public class Foo {
           static public var bar: Int {
               return 42
           }
        }
        """),
        Example("""
        public class Foo {
           class public var bar: Int {
               return 42
           }
        }
        """),
        Example("""
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
        """),
        Example("""
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
        """),
        Example("""
        protocol Foo: class {}
            class Bar {
                private(set) public weak var foo: Foo?
        }
        """),
        Example("""
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
        """),
        Example("""
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
        """),
        Example("""
        @objc
        final public class Foo: NSObject {}
        """),
        Example("""
        @objcMembers
        final public class Foo: NSObject {}
        """),
        Example("""
        @objc
        final open class Foo: NSObject {
           weak open var weakBar: NSString? = nil
        }
        """),
        Example("""
        final public class Foo {}
        """),
        Example("""
        internal class Foo: Bar {
           internal override func bar() {}
        }
        """),
        Example("""
        public struct Foo {
           weak internal var weakBar: NSObjetc? = nil
        }
        """),
        Example("""
        class Foo {
           lazy internal var bar: String = "foo"
        }
        """)
    ]
}
