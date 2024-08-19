internal struct ColonRuleExamples {
    static let nonTriggeringExamples = [
        Example("let abc: Void"),
        Example("let abc: [Void: Void]"),
        Example("let abc: (Void, Void)"),
        Example("let abc: ([Void], String, Int)"),
        Example("let abc: [([Void], String, Int)]"),
        Example("let abc: String=\"def\""),
        Example("let abc: Int=0"),
        Example("let abc: Enum=Enum.Value"),
        Example("func abc(def: Void) {}"),
        Example("func abc(def: Void, ghi: Void) {}"),
        Example("let abc: String = \"abc:\""),
        Example("let abc = [Void: Void]()"),
        Example("let abc = [1: [3: 2], 3: 4]"),
        Example("let abc = [\"string\": \"string\"]"),
        Example("let abc = [\"string:string\": \"string\"]"),
        Example("let abc: [String: Int]"),
        Example("func foo(bar: [String: Int]) {}"),
        Example("func foo() -> [String: Int] { return [:] }"),
        Example("let abc: Any"),
        Example("let abc: [Any: Int]"),
        Example("let abc: [String: Any]"),
        Example("class Foo: Bar {}"),
        Example("class Foo<T>: Bar {}"),
        Example("class Foo<T: Equatable>: Bar {}"),
        Example("class Foo<T, U>: Bar {}"),
        Example("class Foo<T: Equatable> {}"),
        Example("object.method(x: /* comment */ 5)"),
        Example("""
        switch foo {
        case .bar:
            _ = something()
        }
        """),
        Example("object.method(x: 5, y: \"string\")"),
        Example("""
        object.method(x: 5, y:
                      "string")
        """),
        Example("object.method(5, y: \"string\")"),
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
        """),
    ]

    static let triggeringExamples = [
        Example("let abc↓:Void"),
        Example("let abc↓:  Void"),
        Example("let abc↓ :Void"),
        Example("let abc↓ : Void"),
        Example("let abc↓ : [Void: Void]"),
        Example("let abc↓ : (Void, String, Int)"),
        Example("let abc↓ : ([Void], String, Int)"),
        Example("let abc↓ : [([Void], String, Int)]"),
        Example("let abc↓:  (Void, String, Int)"),
        Example("let abc↓:  ([Void], String, Int)"),
        Example("let abc↓:  [([Void], String, Int)]"),
        Example("let abc↓ :String=\"def\""),
        Example("let abc↓ :Int=0"),
        Example("let abc↓ :Int = 0"),
        Example("let abc↓:Int=0"),
        Example("let abc↓:Int = 0"),
        Example("let abc↓:Enum=Enum.Value"),
        Example("func abc(def↓:Void) {}"),
        Example("func abc(def↓:  Void) {}"),
        Example("func abc(def↓ :Void) {}"),
        Example("func abc(def↓ : Void) {}"),
        Example("func abc(def: Void, ghi↓ :Void) {}"),
        Example("let abc = [Void↓:Void]()"),
        Example("let abc = [Void↓ : Void]()"),
        Example("let abc = [Void↓:  Void]()"),
        Example("let abc = [Void↓ :  Void]()"),
        Example("let abc = [1: [3↓ : 2], 3: 4]"),
        Example("let abc = [1: [3↓ : 2], 3↓:  4]"),
        Example("let abc: [String↓ : Int]"),
        Example("let abc: [String↓:Int]"),
        Example("func foo(bar: [String↓ : Int]) {}"),
        Example("func foo(bar: [String↓:Int]) {}"),
        Example("func foo() -> [String↓ : Int] { return [:] }"),
        Example("func foo() -> [String↓:Int] { return [:] }"),
        Example("let abc↓ : Any"),
        Example("let abc: [Any↓ : Int]"),
        Example("let abc: [String↓ : Any]"),
        Example("class Foo↓ : Bar {}"),
        Example("class Foo↓:Bar {}"),
        Example("class Foo<T>↓ : Bar {}"),
        Example("class Foo<T>↓:Bar {}"),
        Example("class Foo<T, U>↓:Bar {}"),
        Example("class Foo<T: Equatable>↓:Bar {}"),
        Example("class Foo<T↓:Equatable> {}"),
        Example("class Foo<T↓ : Equatable> {}"),
        Example("object.method(x: 5, y↓ : \"string\")"),
        Example("object.method(x↓:5, y: \"string\")"),
        Example("object.method(x↓:  5, y: \"string\")"),
        Example("func abc() { def(ghi↓:jkl) }"),
        Example("func abc(def: Void) { ghi(jkl↓:mno) }"),
        Example("class ABC { let def = ghi(jkl↓:mno) } }"),
        Example("func foo() { let dict = [1↓ : 1] }"),
        Example("""
        switch foo {
        case .bar↓ : return baz
        }
        """),
        Example("private var action↓:(() -> Void)?"),
    ]

    static let corrections = [
        Example("let abc↓:Void"): Example("let abc: Void"),
        Example("let abc↓:  Void"): Example("let abc: Void"),
        Example("let abc↓ :Void"): Example("let abc: Void"),
        Example("let abc↓ : Void"): Example("let abc: Void"),
        Example("let abc↓ : [Void: Void]"): Example("let abc: [Void: Void]"),
        Example("let abc↓ : (Void, String, Int)"): Example("let abc: (Void, String, Int)"),
        Example("let abc↓ : ([Void], String, Int)"): Example("let abc: ([Void], String, Int)"),
        Example("let abc↓ : [([Void], String, Int)]"): Example("let abc: [([Void], String, Int)]"),
        Example("let abc↓:  (Void, String, Int)"): Example("let abc: (Void, String, Int)"),
        Example("let abc↓:  ([Void], String, Int)"): Example("let abc: ([Void], String, Int)"),
        Example("let abc↓:  [([Void], String, Int)]"): Example("let abc: [([Void], String, Int)]"),
        Example("let abc↓ :String=\"def\""): Example("let abc: String=\"def\""),
        Example("let abc↓ :Int=0"): Example("let abc: Int=0"),
        Example("let abc↓ :Int = 0"): Example("let abc: Int = 0"),
        Example("let abc↓:Int=0"): Example("let abc: Int=0"),
        Example("let abc↓:Int = 0"): Example("let abc: Int = 0"),
        Example("let abc↓:Enum=Enum.Value"): Example("let abc: Enum=Enum.Value"),
        Example("func abc(def↓:Void) {}"): Example("func abc(def: Void) {}"),
        Example("func abc(def↓:  Void) {}"): Example("func abc(def: Void) {}"),
        Example("func abc(def↓ :Void) {}"): Example("func abc(def: Void) {}"),
        Example("func abc(def↓ : Void) {}"): Example("func abc(def: Void) {}"),
        Example("func abc(def: Void, ghi↓ :Void) {}"): Example("func abc(def: Void, ghi: Void) {}"),
        Example("let abc = [Void↓:Void]()"): Example("let abc = [Void: Void]()"),
        Example("let abc = [Void↓ : Void]()"): Example("let abc = [Void: Void]()"),
        Example("let abc = [Void↓:  Void]()"): Example("let abc = [Void: Void]()"),
        Example("let abc = [Void↓ :  Void]()"): Example("let abc = [Void: Void]()"),
        Example("let abc = [1: [3↓ : 2], 3: 4]"): Example("let abc = [1: [3: 2], 3: 4]"),
        Example("let abc = [1: [3↓ : 2], 3↓:  4]"): Example("let abc = [1: [3: 2], 3: 4]"),
        Example("let abc: [String↓ : Int]"): Example("let abc: [String: Int]"),
        Example("let abc: [String↓:Int]"): Example("let abc: [String: Int]"),
        Example("func foo(bar: [String↓ : Int]) {}"): Example("func foo(bar: [String: Int]) {}"),
        Example("func foo(bar: [String↓:Int]) {}"): Example("func foo(bar: [String: Int]) {}"),
        Example("func foo() -> [String↓ : Int] { return [:] }"):
            Example("func foo() -> [String: Int] { return [:] }"),
        Example("func foo() -> [String↓:Int] { return [:] }"):
            Example("func foo() -> [String: Int] { return [:] }"),
        Example("let abc↓ : Any"): Example("let abc: Any"),
        Example("let abc: [Any↓ : Int]"): Example("let abc: [Any: Int]"),
        Example("let abc: [String↓ : Any]"): Example("let abc: [String: Any]"),
        Example("class Foo↓ : Bar {}"): Example("class Foo: Bar {}"),
        Example("class Foo↓:Bar {}"): Example("class Foo: Bar {}"),
        Example("class Foo<T>↓ : Bar {}"): Example("class Foo<T>: Bar {}"),
        Example("class Foo<T>↓:Bar {}"): Example("class Foo<T>: Bar {}"),
        Example("class Foo<T, U>↓:Bar {}"): Example("class Foo<T, U>: Bar {}"),
        Example("class Foo<T: Equatable>↓:Bar {}"): Example("class Foo<T: Equatable>: Bar {}"),
        Example("class Foo<T↓:Equatable> {}"): Example("class Foo<T: Equatable> {}"),
        Example("class Foo<T↓ : Equatable> {}"): Example("class Foo<T: Equatable> {}"),
        Example("object.method(x: 5, y↓ : \"string\")"): Example("object.method(x: 5, y: \"string\")"),
        Example("object.method(x↓:5, y: \"string\")"): Example("object.method(x: 5, y: \"string\")"),
        Example("object.method(x↓:  5, y: \"string\")"): Example("object.method(x: 5, y: \"string\")"),
        Example("func abc() { def(ghi↓:jkl) }"): Example("func abc() { def(ghi: jkl) }"),
        Example("func abc(def: Void) { ghi(jkl↓:mno) }"): Example("func abc(def: Void) { ghi(jkl: mno) }"),
        Example("class ABC { let def = ghi(jkl↓:mno) } }"): Example("class ABC { let def = ghi(jkl: mno) } }"),
        Example("func foo() { let dict = [1↓ : 1] }"): Example("func foo() { let dict = [1: 1] }"),
        Example("""
        class Foo {
            #if false
            #else
                let bar = [\"key\"↓   : \"value\"]
            #endif
        }
        """):
            Example("""
            class Foo {
                #if false
                #else
                    let bar = [\"key\": \"value\"]
                #endif
            }
            """),
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
        Example("private var action↓:(() -> Void)?"): Example("private var action: (() -> Void)?"),
    ]
}
