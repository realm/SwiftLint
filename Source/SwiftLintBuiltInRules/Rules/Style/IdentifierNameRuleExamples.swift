internal struct IdentifierNameRuleExamples {
    static let nonTriggeringExamples = [
        Example("let myLet = 0"),
        Example("var myVar = 0"),
        Example("private let _myLet = 0"),
        Example("private func _myFunc() {}"),
        Example("fileprivate let _myLet = 0"),
        Example("fileprivate func _myFunc() {}"),
        Example("fileprivate func _myFunc() {}"),
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
        Example("f { $abc in }"),
        Example("""
                class Foo {
                   static let Bar = 0
                }
                """),
        Example("""
                class Foo {
                   static var Bar = 0
                }
                """),
        Example("func √ (arg: Double) -> Double { arg }", configuration: ["additional_operators": "√"]),
    ]

    static let triggeringExamples = [
        Example(
            "let ↓MyLet = 0",
            configuration: ["validates_start_with_lowercase": true],
            excludeFromDocumentation: true
        ),
        Example("class C { static let ↓_myLet = 0 }"),
        Example("class C { class let ↓MyLet = 0 }"),
        Example("class C { static func ↓MyFunc() {} }"),
        Example("class C { class func ↓MyFunc() {} }"),
        Example("private let ↓myLet_ = 0"),
        Example("let ↓myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"),
        Example("var ↓myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0"),
        Example("private let ↓_myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"),
        Example("let ↓i = 0"),
        Example("var ↓aa = 0"),
        Example("private let ↓_i = 0"),
        Example(
            "func ↓IsOperator(name: String) -> Bool",
            configuration: ["validates_start_with_lowercase": "warning"],
            excludeFromDocumentation: true
        ),
        Example(
            "enum Foo { case ↓MyEnum }",
            configuration: ["validates_start_with_lowercase": "error"],
            excludeFromDocumentation: true
        ),
        Example("if let ↓_x {}"),
        Example("guard var ↓x = x else {}"),
        Example("""
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
            """),
        Example("let (↓a, abc) = (1, 1)"),
        Example("if let ↓i {}"),
        Example("for ↓i in [] {}"),
        Example("f { ↓x in }"),
        Example("f { ↓$x in }"),
        Example("f { (x abc: Int, _ ↓x: Int) in }"),
        Example("""
            enum E {
                case ↓c
                case case1(Int)
                case case2(↓a: Int)
                case case3(_ ↓a: Int)
            }
            """),
        Example("""
            class C {
                var ↓x: Int {
                    get { 1 }
                    set(↓y) { x = y }
                }
            }
            """),
        Example("func ↓√ (arg: Double) -> Double { arg }"),
    ]
}
