internal struct ColonRuleExamples {
    static let nonTriggeringExamples = [
        Example("let abc: Void\n"),
        Example("let abc: [Void: Void]\n"),
        Example("let abc: (Void, Void)\n"),
        Example("let abc: ([Void], String, Int)\n"),
        Example("let abc: [([Void], String, Int)]\n"),
        Example("let abc: String=\"def\"\n"),
        Example("let abc: Int=0\n"),
        Example("let abc: Enum=Enum.Value\n"),
        Example("func abc(def: Void) {}\n"),
        Example("func abc(def: Void, ghi: Void) {}\n"),
        Example("let abc: String = \"abc:\""),
        Example("let abc = [Void: Void]()\n"),
        Example("let abc = [1: [3: 2], 3: 4]\n"),
        Example("let abc = [\"string\": \"string\"]\n"),
        Example("let abc = [\"string:string\": \"string\"]\n"),
        Example("let abc: [String: Int]\n"),
        Example("func foo(bar: [String: Int]) {}\n"),
        Example("func foo() -> [String: Int] { return [:] }\n"),
        Example("let abc: Any\n"),
        Example("let abc: [Any: Int]\n"),
        Example("let abc: [String: Any]\n"),
        Example("class Foo: Bar {}\n"),
        Example("class Foo<T>: Bar {}\n"),
        Example("class Foo<T: Equatable>: Bar {}\n"),
        Example("class Foo<T, U>: Bar {}\n"),
        Example("class Foo<T: Equatable> {}\n"),
        Example("object.method(x: /* comment */ 5)\n"),
        Example("""
        switch foo {
        case .bar:
            _ = something()
        }
        """),
        Example("object.method(x: 5, y: \"string\")\n"),
        Example("""
        object.method(x: 5, y:
                      "string")
        """),
        Example("object.method(5, y: \"string\")\n"),
        Example("func abc() { def(ghi: jkl) }"),
        Example("func abc(def: Void) { ghi(jkl: mno) }"),
        Example("class ABC { let def = ghi(jkl: mno) } }"),
        Example("func foo() { let dict = [1: 1] }"),
        Example("""
        let aaa = Self.bbb ? Self.ccc : Self.ddd else {
        return nil
        Example("}
        """),
        Example("range.flatMap(file.syntaxMap.kinds(inByteRange:)) ?? []"),
        Example("""
        @objc(receiveReply:)
        public class func receiveReply(_ reply: bad_instruction_exception_reply_t) -> CInt { 0 }
        """),
        Example(#"""
        switch str {
        case "adlm", "adlam":             return .adlam
        case "aghb", "caucasianalbanian": return .caucasianAlbanian
        default:                          return nil
        }
        """#),
        Example("""
        precedencegroup PipelinePrecedence {
          associativity: left
        }
        infix operator |> : PipelinePrecedence
        """),
        Example("""
        switch scalar {
          case 0x000A...0x000D /* LF ... CR */: return true
          case 0x0085 /* NEXT LINE (NEL) */: return true
          case 0x2028 /* LINE SEPARATOR */: return true
          case 0x2029 /* PARAGRAPH SEPARATOR */: return true
          default: return false
        }
        """)
    ]

    static let triggeringExamples = [
        Example("let abc↓:Void\n"),
        Example("let abc↓:  Void\n"),
        Example("let abc↓ :Void\n"),
        Example("let abc↓ : Void\n"),
        Example("let abc↓ : [Void: Void]\n"),
        Example("let abc↓ : (Void, String, Int)\n"),
        Example("let abc↓ : ([Void], String, Int)\n"),
        Example("let abc↓ : [([Void], String, Int)]\n"),
        Example("let abc↓:  (Void, String, Int)\n"),
        Example("let abc↓:  ([Void], String, Int)\n"),
        Example("let abc↓:  [([Void], String, Int)]\n"),
        Example("let abc↓ :String=\"def\"\n"),
        Example("let abc↓ :Int=0\n"),
        Example("let abc↓ :Int = 0\n"),
        Example("let abc↓:Int=0\n"),
        Example("let abc↓:Int = 0\n"),
        Example("let abc↓:Enum=Enum.Value\n"),
        Example("func abc(def↓:Void) {}\n"),
        Example("func abc(def↓:  Void) {}\n"),
        Example("func abc(def↓ :Void) {}\n"),
        Example("func abc(def↓ : Void) {}\n"),
        Example("func abc(def: Void, ghi↓ :Void) {}\n"),
        Example("let abc = [Void↓:Void]()\n"),
        Example("let abc = [Void↓ : Void]()\n"),
        Example("let abc = [Void↓:  Void]()\n"),
        Example("let abc = [Void↓ :  Void]()\n"),
        Example("let abc = [1: [3↓ : 2], 3: 4]\n"),
        Example("let abc = [1: [3↓ : 2], 3↓:  4]\n"),
        Example("let abc: [String↓ : Int]\n"),
        Example("let abc: [String↓:Int]\n"),
        Example("func foo(bar: [String↓ : Int]) {}\n"),
        Example("func foo(bar: [String↓:Int]) {}\n"),
        Example("func foo() -> [String↓ : Int] { return [:] }\n"),
        Example("func foo() -> [String↓:Int] { return [:] }\n"),
        Example("let abc↓ : Any\n"),
        Example("let abc: [Any↓ : Int]\n"),
        Example("let abc: [String↓ : Any]\n"),
        Example("class Foo↓ : Bar {}\n"),
        Example("class Foo↓:Bar {}\n"),
        Example("class Foo<T>↓ : Bar {}\n"),
        Example("class Foo<T>↓:Bar {}\n"),
        Example("class Foo<T, U>↓:Bar {}\n"),
        Example("class Foo<T: Equatable>↓:Bar {}\n"),
        Example("class Foo<T↓:Equatable> {}\n"),
        Example("class Foo<T↓ : Equatable> {}\n"),
        Example("object.method(x: 5, y↓ : \"string\")\n"),
        Example("object.method(x↓:5, y: \"string\")\n"),
        Example("object.method(x↓:  5, y: \"string\")\n"),
        Example("func abc() { def(ghi↓:jkl) }"),
        Example("func abc(def: Void) { ghi(jkl↓:mno) }"),
        Example("class ABC { let def = ghi(jkl↓:mno) } }"),
        Example("func foo() { let dict = [1↓ : 1] }"),
        Example("""
        switch foo {
        case .bar↓ : return baz
        }
        """),
        Example("private var action↓:(() -> Void)?")
    ]

    static let corrections = [
        Example("let abc↓:Void\n"): Example("let abc: Void\n"),
        Example("let abc↓:  Void\n"): Example("let abc: Void\n"),
        Example("let abc↓ :Void\n"): Example("let abc: Void\n"),
        Example("let abc↓ : Void\n"): Example("let abc: Void\n"),
        Example("let abc↓ : [Void: Void]\n"): Example("let abc: [Void: Void]\n"),
        Example("let abc↓ : (Void, String, Int)\n"): Example("let abc: (Void, String, Int)\n"),
        Example("let abc↓ : ([Void], String, Int)\n"): Example("let abc: ([Void], String, Int)\n"),
        Example("let abc↓ : [([Void], String, Int)]\n"): Example("let abc: [([Void], String, Int)]\n"),
        Example("let abc↓:  (Void, String, Int)\n"): Example("let abc: (Void, String, Int)\n"),
        Example("let abc↓:  ([Void], String, Int)\n"): Example("let abc: ([Void], String, Int)\n"),
        Example("let abc↓:  [([Void], String, Int)]\n"): Example("let abc: [([Void], String, Int)]\n"),
        Example("let abc↓ :String=\"def\"\n"): Example("let abc: String=\"def\"\n"),
        Example("let abc↓ :Int=0\n"): Example("let abc: Int=0\n"),
        Example("let abc↓ :Int = 0\n"): Example("let abc: Int = 0\n"),
        Example("let abc↓:Int=0\n"): Example("let abc: Int=0\n"),
        Example("let abc↓:Int = 0\n"): Example("let abc: Int = 0\n"),
        Example("let abc↓:Enum=Enum.Value\n"): Example("let abc: Enum=Enum.Value\n"),
        Example("func abc(def↓:Void) {}\n"): Example("func abc(def: Void) {}\n"),
        Example("func abc(def↓:  Void) {}\n"): Example("func abc(def: Void) {}\n"),
        Example("func abc(def↓ :Void) {}\n"): Example("func abc(def: Void) {}\n"),
        Example("func abc(def↓ : Void) {}\n"): Example("func abc(def: Void) {}\n"),
        Example("func abc(def: Void, ghi↓ :Void) {}\n"): Example("func abc(def: Void, ghi: Void) {}\n"),
        Example("let abc = [Void↓:Void]()\n"): Example("let abc = [Void: Void]()\n"),
        Example("let abc = [Void↓ : Void]()\n"): Example("let abc = [Void: Void]()\n"),
        Example("let abc = [Void↓:  Void]()\n"): Example("let abc = [Void: Void]()\n"),
        Example("let abc = [Void↓ :  Void]()\n"): Example("let abc = [Void: Void]()\n"),
        Example("let abc = [1: [3↓ : 2], 3: 4]\n"): Example("let abc = [1: [3: 2], 3: 4]\n"),
        Example("let abc = [1: [3↓ : 2], 3↓:  4]\n"): Example("let abc = [1: [3: 2], 3: 4]\n"),
        Example("let abc: [String↓ : Int]\n"): Example("let abc: [String: Int]\n"),
        Example("let abc: [String↓:Int]\n"): Example("let abc: [String: Int]\n"),
        Example("func foo(bar: [String↓ : Int]) {}\n"): Example("func foo(bar: [String: Int]) {}\n"),
        Example("func foo(bar: [String↓:Int]) {}\n"): Example("func foo(bar: [String: Int]) {}\n"),
        Example("func foo() -> [String↓ : Int] { return [:] }\n"):
            Example("func foo() -> [String: Int] { return [:] }\n"),
        Example("func foo() -> [String↓:Int] { return [:] }\n"):
            Example("func foo() -> [String: Int] { return [:] }\n"),
        Example("let abc↓ : Any\n"): Example("let abc: Any\n"),
        Example("let abc: [Any↓ : Int]\n"): Example("let abc: [Any: Int]\n"),
        Example("let abc: [String↓ : Any]\n"): Example("let abc: [String: Any]\n"),
        Example("class Foo↓ : Bar {}\n"): Example("class Foo: Bar {}\n"),
        Example("class Foo↓:Bar {}\n"): Example("class Foo: Bar {}\n"),
        Example("class Foo<T>↓ : Bar {}\n"): Example("class Foo<T>: Bar {}\n"),
        Example("class Foo<T>↓:Bar {}\n"): Example("class Foo<T>: Bar {}\n"),
        Example("class Foo<T, U>↓:Bar {}\n"): Example("class Foo<T, U>: Bar {}\n"),
        Example("class Foo<T: Equatable>↓:Bar {}\n"): Example("class Foo<T: Equatable>: Bar {}\n"),
        Example("class Foo<T↓:Equatable> {}\n"): Example("class Foo<T: Equatable> {}\n"),
        Example("class Foo<T↓ : Equatable> {}\n"): Example("class Foo<T: Equatable> {}\n"),
        Example("object.method(x: 5, y↓ : \"string\")\n"): Example("object.method(x: 5, y: \"string\")\n"),
        Example("object.method(x↓:5, y: \"string\")\n"): Example("object.method(x: 5, y: \"string\")\n"),
        Example("object.method(x↓:  5, y: \"string\")\n"): Example("object.method(x: 5, y: \"string\")\n"),
        Example("func abc() { def(ghi↓:jkl) }"): Example("func abc() { def(ghi: jkl) }"),
        Example("func abc(def: Void) { ghi(jkl↓:mno) }"): Example("func abc(def: Void) { ghi(jkl: mno) }"),
        Example("class ABC { let def = ghi(jkl↓:mno) } }"): Example("class ABC { let def = ghi(jkl: mno) } }"),
        Example("func foo() { let dict = [1↓ : 1] }"): Example("func foo() { let dict = [1: 1] }"),
        Example("class Foo {\n    #if false\n    #else\n        let bar = [\"key\"↓   : \"value\"]\n    #endif\n}"):
            Example("class Foo {\n    #if false\n    #else\n        let bar = [\"key\": \"value\"]\n    #endif\n}"),
        Example("""
        switch foo {
        case .bar↓ : return baz
        }
        """):
            Example("""
            switch foo {
            case .bar: return baz
            }
            """),
        Example("private var action↓:(() -> Void)?"): Example("private var action: (() -> Void)?")
    ]
}
