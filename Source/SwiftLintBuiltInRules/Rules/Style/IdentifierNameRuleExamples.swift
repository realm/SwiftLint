import SwiftLintCore

internal struct IdentifierNameRuleExamples {
    static let nonTriggeringExamples = #examples([
        "let myLet = 0",
        "var myVar = 0",
        "let `my 🤷‍♂️ id` = 0".configuration(["excluded": ["`.+`"]]),
        "private let _myLet = 0",
        "private func _myFunc() {}",
        "fileprivate let _myLet = 0",
        "fileprivate func _myFunc() {}",
        "fileprivate func _myFunc() {}",
        "class Abc { static let MyLet = 0 }",
        "let URL: NSURL? = nil",
        "let XMLString: String? = nil",
        "override var i = 0",
        "enum Foo { case myEnum }",
        "func isOperator(name: String) -> Bool",
        "func typeForKind(_ kind: SwiftDeclarationKind) -> String",
        "func == (lhs: SyntaxToken, rhs: SyntaxToken) -> Bool",
        "override func IsOperator(name: String) -> Bool",
        "enum Foo { case `private` }",
        "enum Foo { case value(String) }",
        "f { $abc in }",
        """
                class Foo {
                   static let Bar = 0
                }
                """,
        """
                class Foo {
                   static var Bar = 0
                }
                """,
        "func √ (arg: Double) -> Double { arg }".configuration(["additional_operators": "√"]),
        "struct Foo<let count: Int> {}",
        "struct Foo<let maxSize: Int, Element> {}",
        "class Foo<let capacity: Int> {}",
    ])

    static let triggeringExamples = #examples([
        "class C { static let ↓_myLet = 0 }",
        "class C { class let ↓MyLet = 0 }",
        "class C { static func ↓MyFunc() {} }",
        "class C { class func ↓MyFunc() {} }",
        "private let ↓myLet_ = 0",
        "let ↓myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0",
        "var ↓myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0",
        "private let ↓_myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0",
        "let ↓i = 0",
        "var ↓aa = 0",
        "let ↓`my 🤷‍♂️ id` = 0",
        "private let ↓_i = 0",
        "func ↓IsOperator(name: String) -> Bool"
            .configuration(["validates_start_with_lowercase": "warning"]).excludeFromDocumentation(),
        "enum Foo { case ↓MyEnum }"
            .configuration(["validates_start_with_lowercase": "error"]).excludeFromDocumentation(),
        "if let ↓_x {}",
        "guard var ↓x = x else {}",
        """
            func myFunc(
                _ ↓s: String,
                i ↓j: Int,
                _ goodName: Double,
                name ↓n: String,
                ↓x: Int,
                abc: Double,
                _: Double,
                last _: Double
            ) {}
            """,
        "let (↓a, abc) = (1, 1)",
        "if let ↓i {}",
        "for ↓i in [] {}",
        "f { ↓x in }",
        "f { ↓$x in }",
        "f { (x abc: Int, _ ↓x: Int) in }",
        """
            enum E {
                case ↓c
                case case1(Int)
                case case2(↓a: Int)
                case case3(_ ↓a: Int)
            }
            """,
        """
            class C {
                var ↓x: Int {
                    get { 1 }
                    set(↓y) { x = y }
                }
            }
            """,
        "func ↓√ (arg: Double) -> Double { arg }",
        "class Foo<let ↓max_count: Int> {}",
        "struct Foo<let ↓c: Int> {}",
    ])
}
