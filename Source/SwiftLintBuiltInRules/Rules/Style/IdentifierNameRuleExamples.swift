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
        Example("""
            func isOperator(name: String) -> Bool
            private func isOperator(name: String) -> Bool
            static func isOperator(name: String) -> Bool
            static private func isOperator(name: String) -> Bool
            """),
        Example("enum Foo { case `private` }"),
        Example("enum Foo { case value(String) }"),
        Example("""
                class Foo {
                   static let Bar = 0
                }
                """),
        Example("""
                class Foo {
                   static var Bar = 0
                }
                """)
    ]

    static let triggeringExamples = [
        Example(
            "↓let MyLet = 0",
            configuration: ["validates_start_with_lowercase": "warning"],
            excludeFromDocumentation: true
        ),
        Example("↓let _myLet = 0"),
        Example("private ↓let myLet_ = 0"),
        Example("↓let myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"),
        Example("↓var myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0"),
        Example("private ↓let _myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"),
        Example("↓let i = 0"),
        Example("↓var aa = 0"),
        Example("private ↓let _i = 0"),
        Example(
            """
            ↓func IsOperator(name: String) -> Bool
            private ↓func IsPrivateOperator(name: String) -> Bool
            static ↓func IsStaticOperator(name: String) -> Bool
            static private ↓func IsPSOperator(name: String) -> Bool
            """,
            configuration: ["validates_start_with_lowercase": "warning"],
            excludeFromDocumentation: true
        ),
        Example(
            "enum Foo { case ↓MyEnum }",
            configuration: ["validates_start_with_lowercase": "error"],
            excludeFromDocumentation: true
        )
    ]
}
