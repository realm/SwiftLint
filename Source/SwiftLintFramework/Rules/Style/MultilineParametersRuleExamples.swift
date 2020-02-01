// swiftlint:disable type_body_length

internal struct MultilineParametersRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        "func foo() { }",
        "func foo(param1: Int) { }",
        "func foo(param1: Int, param2: Bool) { }",
        "func foo(param1: Int, param2: Bool, param3: [String]) { }",
        """
        func foo(param1: Int,
                 param2: Bool,
                 param3: [String]) { }
        """,
        """
        func foo(_ param1: Int, param2: Int, param3: Int) -> (Int) -> Int {
           return { x in x + param1 + param2 + param3 }
        }
        """,
        "static func foo() { }",
        "static func foo(param1: Int) { }",
        "static func foo(param1: Int, param2: Bool) { }",
        "static func foo(param1: Int, param2: Bool, param3: [String]) { }",
        """
        static func foo(param1: Int,
                        param2: Bool,
                        param3: [String]) { }
        """,
        "protocol Foo {\n\tfunc foo() { }\n}",
        "protocol Foo {\n\tfunc foo(param1: Int) { }\n}",
        "protocol Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
        "protocol Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        """
        protocol Foo {
           func foo(param1: Int,
                    param2: Bool,
                    param3: [String]) { }
        }
        """,
        "protocol Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        """
        protocol Foo {
           static func foo(param1: Int,
                           param2: Bool,
                           param3: [String]) { }
        }
        """,
        "protocol Foo {\n\tclass func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        """
        protocol Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: [String]) { }
        }
        """,
        "enum Foo {\n\tfunc foo() { }\n}",
        "enum Foo {\n\tfunc foo(param1: Int) { }\n}",
        "enum Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
        "enum Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        """
        enum Foo {
           func foo(param1: Int,
                    param2: Bool,
                    param3: [String]) { }
        }
        """,
        "enum Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        """
        enum Foo {
           static func foo(param1: Int,
                           param2: Bool,
                           param3: [String]) { }
        }
        """,
        "struct Foo {\n\tfunc foo() { }\n}",
        "struct Foo {\n\tfunc foo(param1: Int) { }\n}",
        "struct Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
        "struct Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        """
        struct Foo {
           func foo(param1: Int,
                    param2: Bool,
                    param3: [String]) { }
        }
        """,
        "struct Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        """
        struct Foo {
           static func foo(param1: Int,
                           param2: Bool,
                           param3: [String]) { }
        }
        """,
        "class Foo {\n\tfunc foo() { }\n}",
        "class Foo {\n\tfunc foo(param1: Int) { }\n}",
        "class Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
        "class Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n\t}",
        """
        class Foo {
           func foo(param1: Int,
                    param2: Bool,
                    param3: [String]) { }
        }
        """,
        "class Foo {\n\tclass func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        """
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: [String]) { }
        }
        """,
        """
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping (Int, Int) -> Void = { _, _ in }) { }
        }
        """,
        """
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping (Int) -> Void = { _ in }) { }
        }
        """,
        """
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping ((Int) -> Void)? = nil) { }
        }
        """,
        """
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping ((Int) -> Void)? = { _ in }) { }
        }
        """,
        """
        class Foo {
           class func foo(param1: Int,
                          param2: @escaping ((Int) -> Void)? = { _ in },
                          param3: Bool) { }
        }
        """,
        """
        class Foo {
           class func foo(param1: Int,
                          param2: @escaping ((Int) -> Void)? = { _ in },
                          param3: @escaping (Int, Int) -> Void = { _, _ in }) { }
        }
        """,
        """
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping (Int) -> Void = { (x: Int) in }) { }
        }
        """,
        """
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping (Int, (Int) -> Void) -> Void = { (x: Int, f: (Int) -> Void) in }) { }
        }
        """
    ]

    static let triggeringExamples: [Example] = [
        """
        func ↓foo(_ param1: Int,
                  param2: Int, param3: Int) -> (Int) -> Int {
           return { x in x + param1 + param2 + param3 }
        }
        """,
        """
        protocol Foo {
           func ↓foo(param1: Int,
                     param2: Bool, param3: [String]) { }
        }
        """,
        """
        protocol Foo {
           func ↓foo(param1: Int, param2: Bool,
                     param3: [String]) { }
        }
        """,
        """
        protocol Foo {
           static func ↓foo(param1: Int,
                            param2: Bool, param3: [String]) { }
        }
        """,
        """
        protocol Foo {
           static func ↓foo(param1: Int, param2: Bool,
                            param3: [String]) { }
        }
        """,
        """
        protocol Foo {
           class func ↓foo(param1: Int,
                           param2: Bool, param3: [String]) { }
        }
        """,
        """
        protocol Foo {
           class func ↓foo(param1: Int, param2: Bool,
                           param3: [String]) { }
        }
        """,
        """
        enum Foo {
           func ↓foo(param1: Int,
                     param2: Bool, param3: [String]) { }
        }
        """,
        """
        enum Foo {
           func ↓foo(param1: Int, param2: Bool,
                     param3: [String]) { }
        }
        """,
        """
        enum Foo {
           static func ↓foo(param1: Int,
                            param2: Bool, param3: [String]) { }
        }
        """,
        """
        enum Foo {
           static func ↓foo(param1: Int, param2: Bool,
                            param3: [String]) { }
        }
        """,
        """
        struct Foo {
           func ↓foo(param1: Int,
                     param2: Bool, param3: [String]) { }
        }
        """,
        """
        struct Foo {
           func ↓foo(param1: Int, param2: Bool,
                     param3: [String]) { }
        }
        """,
        """
        struct Foo {
           static func ↓foo(param1: Int,
                            param2: Bool, param3: [String]) { }
        }
        """,
        """
        struct Foo {
           static func ↓foo(param1: Int, param2: Bool,
                            param3: [String]) { }
        }
        """,
        """
        class Foo {
           func ↓foo(param1: Int,
                     param2: Bool, param3: [String]) { }
        }
        """,
        """
        class Foo {
           func ↓foo(param1: Int, param2: Bool,
                     param3: [String]) { }
        }
        """,
        """
        class Foo {
           class func ↓foo(param1: Int,
                           param2: Bool, param3: [String]) { }
        }
        """,
        """
        class Foo {
           class func ↓foo(param1: Int, param2: Bool,
                           param3: [String]) { }
        }
        """,
        """
        class Foo {
           class func ↓foo(param1: Int,
                          param2: Bool, param3: @escaping (Int, Int) -> Void = { _, _ in }) { }
        }
        """,
        """
        class Foo {
           class func ↓foo(param1: Int,
                          param2: Bool, param3: @escaping (Int) -> Void = { (x: Int) in }) { }
        }
        """
    ]
}
