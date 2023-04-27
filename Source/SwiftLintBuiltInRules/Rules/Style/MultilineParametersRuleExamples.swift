internal struct MultilineParametersRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("func foo() { }"),
        Example("func foo(param1: Int) { }"),
        Example("func foo(param1: Int, param2: Bool) { }"),
        Example("func foo(param1: Int, param2: Bool, param3: [String]) { }"),
        Example("""
        func foo(param1: Int,
                 param2: Bool,
                 param3: [String]) { }
        """),
        Example("""
        func foo(_ param1: Int, param2: Int, param3: Int) -> (Int) -> Int {
           return { x in x + param1 + param2 + param3 }
        }
        """),
        Example("static func foo() { }"),
        Example("static func foo(param1: Int) { }"),
        Example("static func foo(param1: Int, param2: Bool) { }"),
        Example("static func foo(param1: Int, param2: Bool, param3: [String]) { }"),
        Example("""
        static func foo(param1: Int,
                        param2: Bool,
                        param3: [String]) { }
        """),
        Example("protocol Foo {\n\tfunc foo() { }\n}"),
        Example("protocol Foo {\n\tfunc foo(param1: Int) { }\n}"),
        Example("protocol Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}"),
        Example("protocol Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}"),
        Example("""
        protocol Foo {
           func foo(param1: Int,
                    param2: Bool,
                    param3: [String]) { }
        }
        """),
        Example("protocol Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}"),
        Example("""
        protocol Foo {
           static func foo(param1: Int,
                           param2: Bool,
                           param3: [String]) { }
        }
        """),
        Example("protocol Foo {\n\tclass func foo(param1: Int, param2: Bool, param3: [String]) { }\n}"),
        Example("""
        protocol Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: [String]) { }
        }
        """),
        Example("enum Foo {\n\tfunc foo() { }\n}"),
        Example("enum Foo {\n\tfunc foo(param1: Int) { }\n}"),
        Example("enum Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}"),
        Example("enum Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}"),
        Example("""
        enum Foo {
           func foo(param1: Int,
                    param2: Bool,
                    param3: [String]) { }
        }
        """),
        Example("enum Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}"),
        Example("""
        enum Foo {
           static func foo(param1: Int,
                           param2: Bool,
                           param3: [String]) { }
        }
        """),
        Example("struct Foo {\n\tfunc foo() { }\n}"),
        Example("struct Foo {\n\tfunc foo(param1: Int) { }\n}"),
        Example("struct Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}"),
        Example("struct Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}"),
        Example("""
        struct Foo {
           func foo(param1: Int,
                    param2: Bool,
                    param3: [String]) { }
        }
        """),
        Example("struct Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}"),
        Example("""
        struct Foo {
           static func foo(param1: Int,
                           param2: Bool,
                           param3: [String]) { }
        }
        """),
        Example("class Foo {\n\tfunc foo() { }\n}"),
        Example("class Foo {\n\tfunc foo(param1: Int) { }\n}"),
        Example("class Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}"),
        Example("class Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n\t}"),
        Example("""
        class Foo {
           func foo(param1: Int,
                    param2: Bool,
                    param3: [String]) { }
        }
        """),
        Example("class Foo {\n\tclass func foo(param1: Int, param2: Bool, param3: [String]) { }\n}"),
        Example("""
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: [String]) { }
        }
        """),
        Example("""
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping (Int, Int) -> Void = { _, _ in }) { }
        }
        """),
        Example("""
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping (Int) -> Void = { _ in }) { }
        }
        """),
        Example("""
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping ((Int) -> Void)? = nil) { }
        }
        """),
        Example("""
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping ((Int) -> Void)? = { _ in }) { }
        }
        """),
        Example("""
        class Foo {
           class func foo(param1: Int,
                          param2: @escaping ((Int) -> Void)? = { _ in },
                          param3: Bool) { }
        }
        """),
        Example("""
        class Foo {
           class func foo(param1: Int,
                          param2: @escaping ((Int) -> Void)? = { _ in },
                          param3: @escaping (Int, Int) -> Void = { _, _ in }) { }
        }
        """),
        Example("""
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping (Int) -> Void = { (x: Int) in }) { }
        }
        """),
        Example("""
        class Foo {
           class func foo(param1: Int,
                          param2: Bool,
                          param3: @escaping (Int, (Int) -> Void) -> Void = { (x: Int, f: (Int) -> Void) in }) { }
        }
        """),
        Example("""
        class Foo {
           init(param1: Int,
                param2: Bool,
                param3: @escaping ((Int) -> Void)? = { _ in }) { }
        }
        """),
        Example("func foo() { }",
                configuration: ["allows_single_line": false]),
        Example("func foo(param1: Int) { }",
                configuration: ["allows_single_line": false]),
        Example("""
        protocol Foo {
            func foo(param1: Int,
                     param2: Bool,
                     param3: [String]) { }
        }
        """, configuration: ["allows_single_line": false]),
        Example("""
        protocol Foo {
            func foo(
                param1: Int
            ) { }
        }
        """, configuration: ["allows_single_line": false]),
        Example("""
        protocol Foo {
            func foo(
                param1: Int,
                param2: Bool,
                param3: [String]
            ) { }
        }
        """, configuration: ["allows_single_line": false])
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        func ↓foo(_ param1: Int,
                  param2: Int, param3: Int) -> (Int) -> Int {
           return { x in x + param1 + param2 + param3 }
        }
        """),
        Example("""
        protocol Foo {
           func ↓foo(param1: Int,
                     param2: Bool, param3: [String]) { }
        }
        """),
        Example("""
        protocol Foo {
           func ↓foo(param1: Int, param2: Bool,
                     param3: [String]) { }
        }
        """),
        Example("""
        protocol Foo {
           static func ↓foo(param1: Int,
                            param2: Bool, param3: [String]) { }
        }
        """),
        Example("""
        protocol Foo {
           static func ↓foo(param1: Int, param2: Bool,
                            param3: [String]) { }
        }
        """),
        Example("""
        protocol Foo {
           class func ↓foo(param1: Int,
                           param2: Bool, param3: [String]) { }
        }
        """),
        Example("""
        protocol Foo {
           class func ↓foo(param1: Int, param2: Bool,
                           param3: [String]) { }
        }
        """),
        Example("""
        enum Foo {
           func ↓foo(param1: Int,
                     param2: Bool, param3: [String]) { }
        }
        """),
        Example("""
        enum Foo {
           func ↓foo(param1: Int, param2: Bool,
                     param3: [String]) { }
        }
        """),
        Example("""
        enum Foo {
           static func ↓foo(param1: Int,
                            param2: Bool, param3: [String]) { }
        }
        """),
        Example("""
        enum Foo {
           static func ↓foo(param1: Int, param2: Bool,
                            param3: [String]) { }
        }
        """),
        Example("""
        struct Foo {
           func ↓foo(param1: Int,
                     param2: Bool, param3: [String]) { }
        }
        """),
        Example("""
        struct Foo {
           func ↓foo(param1: Int, param2: Bool,
                     param3: [String]) { }
        }
        """),
        Example("""
        struct Foo {
           static func ↓foo(param1: Int,
                            param2: Bool, param3: [String]) { }
        }
        """),
        Example("""
        struct Foo {
           static func ↓foo(param1: Int, param2: Bool,
                            param3: [String]) { }
        }
        """),
        Example("""
        class Foo {
           func ↓foo(param1: Int,
                     param2: Bool, param3: [String]) { }
        }
        """),
        Example("""
        class Foo {
           func ↓foo(param1: Int, param2: Bool,
                     param3: [String]) { }
        }
        """),
        Example("""
        class Foo {
           class func ↓foo(param1: Int,
                           param2: Bool, param3: [String]) { }
        }
        """),
        Example("""
        class Foo {
           class func ↓foo(param1: Int, param2: Bool,
                           param3: [String]) { }
        }
        """),
        Example("""
        class Foo {
           class func ↓foo(param1: Int,
                          param2: Bool, param3: @escaping (Int, Int) -> Void = { _, _ in }) { }
        }
        """),
        Example("""
        class Foo {
           class func ↓foo(param1: Int,
                          param2: Bool, param3: @escaping (Int) -> Void = { (x: Int) in }) { }
        }
        """),
        Example("""
        class Foo {
          ↓init(param1: Int, param2: Bool,
                param3: @escaping ((Int) -> Void)? = { _ in }) { }
        }
        """),
        Example("func ↓foo(param1: Int, param2: Bool) { }",
                configuration: ["allows_single_line": false]),
        Example("func ↓foo(param1: Int, param2: Bool, param3: [String]) { }",
                configuration: ["allows_single_line": false])
    ]
}
