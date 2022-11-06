internal struct IdentifierNameRuleExamples {
    static let nonTriggeringExamples = [
        Example("let myLet = 0"),
        Example("var myVar = 0"),
        Example("private let _myLet = 0"),
        Example("class Abc { static let MyLet = 0 }"),
        Example("let URL: NSURL? = nil"),
        Example("let XMLString: String? = nil"),
        Example("override var i = 0"),
        Example("enum Foo { case myEnum }"),
        Example("func isOperator(name: String) -> Bool"),
        Example("func typeForKind(_ kind: SwiftDeclarationKind) -> String"),
        Example("func == (lhs: SyntaxToken, rhs: SyntaxToken) -> Bool"),
        Example("override func IsOperator(name: String) -> Bool"),
        Example("enum Foo { case `private` }"),
        Example("enum Foo { case value(String) }"),
        Example("func group<U: Hashable>(by transform: (Element) -> U) -> [U: [Element]] {}")
    ]

    static let triggeringExamples = [
        Example("↓let MyLet = 0"),
        Example("↓let _myLet = 0"),
        Example("private ↓let myLet_ = 0"),
        Example("↓let myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"),
        Example("↓var myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0"),
        Example("private ↓let _myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"),
        Example("↓let i = 0"),
        Example("↓var aa = 0"),
        Example("private ↓let _i = 0"),
        Example("↓func IsOperator(name: String) -> Bool"),
        Example("func something(↓x: Int) -> Bool"),
        Example("enum Foo { case ↓MyEnum }"),
        Example("list.first { ↓l in l == 1 }"),
        Example("for ↓i in 0..<10 {}"),
        Example("""
        class MyClass {
            ↓static var x: Int
        }
        """),
        Example("""
        class MyClass {
            ↓class let i = 0
        }
        """)
    ]
}
