internal struct ModifierOrderRuleExamples {
    static let nonTriggeringExamples = [
        "public class Foo { \n"                                 +
        "   public convenience required init() {} \n"           +
        "}",
        "public class Foo { \n"                                 +
        "   public static let bar = 42 \n"                      +
        "}",
        "public class Foo { \n"                                 +
        "   public static var bar: Int { \n"                    +
        "       return 42"                                      +
        "   }"                                                  +
        "}",
        "public class Foo { \n"                                 +
        "   public class var bar: Int { \n"                     +
        "       return 42 \n"                                   +
        "   } \n"                                               +
        "}",
        "public class Bar { \n"                                 +
        "   public class var foo: String { \n"                  +
        "       return \"foo\" \n"                              +
        "   } \n"                                               +
        "} \n"                                                  +
        "public class Foo: Bar { \n"                            +
        "   override public final class var foo: String { \n"   +
        "       return \"bar\" \n"                              +
        "   } \n"                                               +
        "}",
        "open class Bar { \n"                                   +
        "   public var foo: Int? { \n"                          +
        "       return 42 \n"                                   +
        "   } \n"                                               +
        "} \n"                                                  +
        "open class Foo: Bar { \n"                              +
        "   override public var foo: Int? { \n"                 +
        "       return 43 \n"                                   +
        "   } \n"                                               +
        "}",
        "open class Bar { \n"                                   +
        "   open class func foo() -> Int { \n"                  +
        "       return 42 \n"                                   +
        "   } \n"                                               +
        "} \n"                                                  +
        "class Foo: Bar { \n"                                   +
        "   override open class func foo() -> Int { \n"         +
        "       return 43 \n"                                   +
        "   } \n"                                               +
        "}",
        "protocol Foo: class {} \n"                             +
        "class Bar { \n"                                        +
        "    public private(set) weak var foo: Foo? \n"         +
        "} \n",
        "@objc \n"                                              +
        "public final class Foo: NSObject {} \n",
        "@objcMembers \n"                                       +
        "public final class Foo: NSObject {} \n",
        "@objc \n"                                              +
        "override public private(set) weak var foo: Bar? \n",
        "@objc \n"                                              +
        "public final class Foo: NSObject {} \n",
        "@objc \n"                                              +
        "open final class Foo: NSObject { \n"                   +
        "   open weak var weakBar: NSString? = nil \n"          +
        "}",
        "public final class Foo {}",
        "class Bar { \n"                                        +
        "   func bar() {} \n"                                   +
        "}",
        "internal class Foo: Bar { \n"                          +
        "   override internal func bar() {} \n"                 +
        "}",
        "public struct Foo { \n"                                +
        "   internal weak var weakBar: NSObject? = nil \n"      +
        "}",
        "class Foo { \n"                                        +
        "   internal lazy var bar: String = \"foo\" \n"         +
        "}"
    ]

    static let triggeringExamples = [
        "class Foo { \n"                                        +
        "   convenience required public init() {} \n"           +
        "}",
        "public class Foo { \n"                                 +
        "   static public let bar = 42 \n"                      +
        "}",
        "public class Foo { \n"                                 +
        "   static public var bar: Int { \n"                    +
        "       return 42 \n"                                   +
        "   } \n"                                               +
        "} \n",
        "public class Foo { \n"                                 +
        "   class public var bar: Int { \n"                     +
        "       return 42 \n"                                   +
        "   } \n"                                               +
        "}",
        "public class RootFoo { \n"                             +
        "   class public var foo: String { \n"                  +
        "       return \"foo\" \n"                              +
        "   } \n"                                               +
        "} \n"                                                  +
        "public class Foo: RootFoo { \n"                        +
        "   override final class public var foo: String { \n"   +
        "       return \"bar\" \n"                              +
        "   } \n"                                               +
        "}",
        "open class Bar { \n"                                   +
        "   public var foo: Int? { \n"                          +
        "       return 42 \n"                                   +
        "   } \n"                                               +
        "} \n"                                                  +
        "open class Foo: Bar { \n"                              +
        "    public override var foo: Int? { \n"                +
        "       return 43 \n"                                   +
        "   } \n"                                               +
        "}",
        "protocol Foo: class {} \n"                             +
            "class Bar { \n"                                    +
            "    private(set) public weak var foo: Foo? \n"     +
        "} \n",
        "open class Bar { \n"                                   +
        "   open class func foo() -> Int { \n"                  +
        "       return 42 \n"                                   +
        "   } \n"                                               +
        "} \n"                                                  +
        "class Foo: Bar { \n"                                   +
        "   class open override func foo() -> Int { \n"         +
        "       return 43 \n"                                   +
        "   } \n"                                               +
        "}",
        "open class Bar { \n"                                   +
        "   open class func foo() -> Int { \n"                  +
        "       return 42 \n"                                   +
        "   } \n"                                               +
        "} \n"                                                  +
        "class Foo: Bar { \n"                                   +
        "   open override class func foo() -> Int { \n"         +
        "       return 43 \n"                                   +
        "   } \n"                                               +
        "}",
        "@objc \n"                                              +
        "final public class Foo: NSObject {}",
        "@objcMembers \n"                                       +
        "final public class Foo: NSObject {}",
        "@objc \n"                                              +
        "final open class Foo: NSObject { \n"                   +
        "   weak open var weakBar: NSString? = nil \n"          +
        "}",
        "final public class Foo {} \n",
        "internal class Foo: Bar { \n"                          +
        "   internal override func bar() {} \n"                 +
        "}",
        "public struct Foo { \n"                                +
        "   weak internal var weakBar: NSObjetc? = nil \n"      +
        "}",
        "class Foo { \n"                                        +
        "   lazy internal var bar: String = \"foo\" \n"         +
        "}"
    ]
}
