// swiftlint:disable type_body_length

internal struct MultilineParametersRuleExamples {
    static let nonTriggeringExamples = [
        "func foo() { }",
        "func foo(param1: Int) { }",
        "func foo(param1: Int, param2: Bool) { }",
        "func foo(param1: Int, param2: Bool, param3: [String]) { }",
        "func foo(param1: Int,\n" +
        "         param2: Bool,\n" +
        "         param3: [String]) { }",
        "func foo(_ param1: Int, param2: Int, param3: Int) -> (Int) -> Int {\n" +
        "   return { x in x + param1 + param2 + param3 }\n" +
        "}",
        "static func foo() { }",
        "static func foo(param1: Int) { }",
        "static func foo(param1: Int, param2: Bool) { }",
        "static func foo(param1: Int, param2: Bool, param3: [String]) { }",
        "static func foo(param1: Int,\n" +
        "                param2: Bool,\n" +
        "                param3: [String]) { }",
        "protocol Foo {\n\tfunc foo() { }\n}",
        "protocol Foo {\n\tfunc foo(param1: Int) { }\n}",
        "protocol Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
        "protocol Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        "protocol Foo {\n" +
        "   func foo(param1: Int,\n" +
        "            param2: Bool,\n" +
        "            param3: [String]) { }\n" +
        "}",
        "protocol Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        "protocol Foo {\n" +
        "   static func foo(param1: Int,\n" +
        "                   param2: Bool,\n" +
        "                   param3: [String]) { }\n" +
        "}",
        "protocol Foo {\n\tclass func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        "protocol Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: Bool,\n" +
        "                  param3: [String]) { }\n" +
        "}",
        "enum Foo {\n\tfunc foo() { }\n}",
        "enum Foo {\n\tfunc foo(param1: Int) { }\n}",
        "enum Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
        "enum Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        "enum Foo {\n" +
        "   func foo(param1: Int,\n" +
        "            param2: Bool,\n" +
        "            param3: [String]) { }\n" +
        "}",
        "enum Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        "enum Foo {\n" +
        "   static func foo(param1: Int,\n" +
        "                   param2: Bool,\n" +
        "                   param3: [String]) { }\n" +
        "}",
        "struct Foo {\n\tfunc foo() { }\n}",
        "struct Foo {\n\tfunc foo(param1: Int) { }\n}",
        "struct Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
        "struct Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        "struct Foo {\n" +
        "   func foo(param1: Int,\n" +
        "            param2: Bool,\n" +
        "            param3: [String]) { }\n" +
        "}",
        "struct Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        "struct Foo {\n" +
        "   static func foo(param1: Int,\n" +
        "                   param2: Bool,\n" +
        "                   param3: [String]) { }\n" +
        "}",
        "class Foo {\n\tfunc foo() { }\n}",
        "class Foo {\n\tfunc foo(param1: Int) { }\n}",
        "class Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
        "class Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n\t}",
        "class Foo {\n" +
        "   func foo(param1: Int,\n" +
        "            param2: Bool,\n" +
        "            param3: [String]) { }\n" +
        "}",
        "class Foo {\n\tclass func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
        "class Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: Bool,\n" +
        "                  param3: [String]) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: Bool,\n" +
        "                  param3: @escaping (Int, Int) -> Void = { _, _ in }) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: Bool,\n" +
        "                  param3: @escaping (Int) -> Void = { _ in }) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: Bool,\n" +
        "                  param3: @escaping ((Int) -> Void)? = nil) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: Bool,\n" +
        "                  param3: @escaping ((Int) -> Void)? = { _ in }) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: @escaping ((Int) -> Void)? = { _ in },\n" +
        "                  param3: Bool) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: @escaping ((Int) -> Void)? = { _ in },\n" +
        "                  param3: @escaping (Int, Int) -> Void = { _, _ in }) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: Bool,\n" +
        "                  param3: @escaping (Int) -> Void = { (x: Int) in }) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func foo(param1: Int,\n" +
        "                  param2: Bool,\n" +
        "                  param3: @escaping (Int, (Int) -> Void) -> Void = { (x: Int, f: (Int) -> Void) in }) { }\n" +
        "}"
    ]

    static let triggeringExamples = [
        "func ↓foo(_ param1: Int,\n" +
        "          param2: Int, param3: Int) -> (Int) -> Int {\n" +
        "   return { x in x + param1 + param2 + param3 }\n" +
        "}",
        "protocol Foo {\n" +
        "   func ↓foo(param1: Int,\n" +
        "             param2: Bool, param3: [String]) { }\n" +
        "}",
        "protocol Foo {\n" +
        "   func ↓foo(param1: Int, param2: Bool,\n" +
        "             param3: [String]) { }\n" +
        "}",
        "protocol Foo {\n" +
        "   static func ↓foo(param1: Int,\n" +
        "                    param2: Bool, param3: [String]) { }\n" +
        "}",
        "protocol Foo {\n" +
        "   static func ↓foo(param1: Int, param2: Bool,\n" +
        "                    param3: [String]) { }\n" +
        "}",
        "protocol Foo {\n" +
        "   class func ↓foo(param1: Int,\n" +
        "                   param2: Bool, param3: [String]) { }\n" +
        "}",
        "protocol Foo {\n" +
        "   class func ↓foo(param1: Int, param2: Bool,\n" +
        "                   param3: [String]) { }\n" +
        "}",
        "enum Foo {\n" +
        "   func ↓foo(param1: Int,\n" +
        "             param2: Bool, param3: [String]) { }\n" +
        "}",
        "enum Foo {\n" +
        "   func ↓foo(param1: Int, param2: Bool,\n" +
        "             param3: [String]) { }\n" +
        "}",
        "enum Foo {\n" +
        "   static func ↓foo(param1: Int,\n" +
        "                    param2: Bool, param3: [String]) { }\n" +
        "}",
        "enum Foo {\n" +
        "   static func ↓foo(param1: Int, param2: Bool,\n" +
        "                    param3: [String]) { }\n" +
        "}",
        "struct Foo {\n" +
        "   func ↓foo(param1: Int,\n" +
        "             param2: Bool, param3: [String]) { }\n" +
        "}",
        "struct Foo {\n" +
        "   func ↓foo(param1: Int, param2: Bool,\n" +
        "             param3: [String]) { }\n" +
        "}",
        "struct Foo {\n" +
        "   static func ↓foo(param1: Int,\n" +
        "                    param2: Bool, param3: [String]) { }\n" +
        "}",
        "struct Foo {\n" +
        "   static func ↓foo(param1: Int, param2: Bool,\n" +
        "                    param3: [String]) { }\n" +
        "}",
        "class Foo {\n" +
        "   func ↓foo(param1: Int,\n" +
        "             param2: Bool, param3: [String]) { }\n" +
        "}",
        "class Foo {\n" +
        "   func ↓foo(param1: Int, param2: Bool,\n" +
        "             param3: [String]) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func ↓foo(param1: Int,\n" +
        "                   param2: Bool, param3: [String]) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func ↓foo(param1: Int, param2: Bool,\n" +
        "                   param3: [String]) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func ↓foo(param1: Int,\n" +
        "                  param2: Bool, param3: @escaping (Int, Int) -> Void = { _, _ in }) { }\n" +
        "}",
        "class Foo {\n" +
        "   class func ↓foo(param1: Int,\n" +
        "                  param2: Bool, param3: @escaping (Int) -> Void = { (x: Int) in }) { }\n" +
        "}"
    ]
}
