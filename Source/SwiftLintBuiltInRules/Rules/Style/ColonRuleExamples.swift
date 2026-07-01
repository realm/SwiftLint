internal struct ColonRuleExamples {
    static let nonTriggeringExamples = #examples([
        "let abc: Void",
        "let abc: [Void: Void]",
        "let abc: (Void, Void)",
        "let abc: ([Void], String, Int)",
        "let abc: [([Void], String, Int)]",
        "let abc: String=\"def\"",
        "let abc: Int=0",
        "let abc: Enum=Enum.Value",
        "func abc(def: Void) {}",
        "func abc(def: Void, ghi: Void) {}",
        "let abc: String = \"abc:\"",
        "let abc = [Void: Void]()",
        "let abc = [1: [3: 2], 3: 4]",
        "let abc = [\"string\": \"string\"]",
        "let abc = [\"string:string\": \"string\"]",
        "let abc: [String: Int]",
        "func foo(bar: [String: Int]) {}",
        "func foo() -> [String: Int] { return [:] }",
        "let abc: Any",
        "let abc: [Any: Int]",
        "let abc: [String: Any]",
        "class Foo: Bar {}",
        "class Foo<T>: Bar {}",
        "class Foo<T: Equatable>: Bar {}",
        "class Foo<T, U>: Bar {}",
        "class Foo<T: Equatable> {}",
        "object.method(x: /* comment */ 5)",
        """
        switch foo {
        case .bar:
            _ = something()
        }
        """,
        "object.method(x: 5, y: \"string\")",
        """
        object.method(x: 5, y:
                      "string")
        """,
        "object.method(5, y: \"string\")",
        "func abc() { def(ghi: jkl) }",
        "func abc(def: Void) { ghi(jkl: mno) }",
        "class ABC { let def = ghi(jkl: mno) } }",
        "func foo() { let dict = [1: 1] }",
        """
        let aaa = Self.bbb ? Self.ccc : Self.ddd else {
        return nil
        Example("}
        """,
        "range.flatMap(file.syntaxMap.kinds(inByteRange:)) ?? []",
        """
        @objc(receiveReply:)
        public class func receiveReply(_ reply: bad_instruction_exception_reply_t) -> CInt { 0 }
        """,
        #"""
        switch str {
        case "adlm", "adlam":             return .adlam
        case "aghb", "caucasianalbanian": return .caucasianAlbanian
        default:                          return nil
        }
        """#,
        """
        precedencegroup PipelinePrecedence {
          associativity: left
        }
        infix operator |> : PipelinePrecedence
        """,
        """
        switch scalar {
          case 0x000A...0x000D /* LF ... CR */: return true
          case 0x0085 /* NEXT LINE (NEL) */: return true
          case 0x2028 /* LINE SEPARATOR */: return true
          case 0x2029 /* PARAGRAPH SEPARATOR */: return true
          default: return false
        }
        """,
    ])

    static let triggeringExamples = #examples([
        "let abc↓:Void",
        "let abc↓:  Void",
        "let abc↓ :Void",
        "let abc↓ : Void",
        "let abc↓ : [Void: Void]",
        "let abc↓ : (Void, String, Int)",
        "let abc↓ : ([Void], String, Int)",
        "let abc↓ : [([Void], String, Int)]",
        "let abc↓:  (Void, String, Int)",
        "let abc↓:  ([Void], String, Int)",
        "let abc↓:  [([Void], String, Int)]",
        "let abc↓ :String=\"def\"",
        "let abc↓ :Int=0",
        "let abc↓ :Int = 0",
        "let abc↓:Int=0",
        "let abc↓:Int = 0",
        "let abc↓:Enum=Enum.Value",
        "func abc(def↓:Void) {}",
        "func abc(def↓:  Void) {}",
        "func abc(def↓ :Void) {}",
        "func abc(def↓ : Void) {}",
        "func abc(def: Void, ghi↓ :Void) {}",
        "let abc = [Void↓:Void]()",
        "let abc = [Void↓ : Void]()",
        "let abc = [Void↓:  Void]()",
        "let abc = [Void↓ :  Void]()",
        "let abc = [1: [3↓ : 2], 3: 4]",
        "let abc = [1: [3↓ : 2], 3↓:  4]",
        "let abc: [String↓ : Int]",
        "let abc: [String↓:Int]",
        "func foo(bar: [String↓ : Int]) {}",
        "func foo(bar: [String↓:Int]) {}",
        "func foo() -> [String↓ : Int] { return [:] }",
        "func foo() -> [String↓:Int] { return [:] }",
        "let abc↓ : Any",
        "let abc: [Any↓ : Int]",
        "let abc: [String↓ : Any]",
        "class Foo↓ : Bar {}",
        "class Foo↓:Bar {}",
        "class Foo<T>↓ : Bar {}",
        "class Foo<T>↓:Bar {}",
        "class Foo<T, U>↓:Bar {}",
        "class Foo<T: Equatable>↓:Bar {}",
        "class Foo<T↓:Equatable> {}",
        "class Foo<T↓ : Equatable> {}",
        "object.method(x: 5, y↓ : \"string\")",
        "object.method(x↓:5, y: \"string\")",
        "object.method(x↓:  5, y: \"string\")",
        "func abc() { def(ghi↓:jkl) }",
        "func abc(def: Void) { ghi(jkl↓:mno) }",
        "class ABC { let def = ghi(jkl↓:mno) } }",
        "func foo() { let dict = [1↓ : 1] }",
        """
        switch foo {
        case .bar↓ : return baz
        }
        """,
        "private var action↓:(() -> Void)?",
    ])

    static let corrections = #corrections([
        "let abc↓:Void": "let abc: Void",
        "let abc↓:  Void": "let abc: Void",
        "let abc↓ :Void": "let abc: Void",
        "let abc↓ : Void": "let abc: Void",
        "let abc↓ : [Void: Void]": "let abc: [Void: Void]",
        "let abc↓ : (Void, String, Int)": "let abc: (Void, String, Int)",
        "let abc↓ : ([Void], String, Int)": "let abc: ([Void], String, Int)",
        "let abc↓ : [([Void], String, Int)]": "let abc: [([Void], String, Int)]",
        "let abc↓:  (Void, String, Int)": "let abc: (Void, String, Int)",
        "let abc↓:  ([Void], String, Int)": "let abc: ([Void], String, Int)",
        "let abc↓:  [([Void], String, Int)]": "let abc: [([Void], String, Int)]",
        "let abc↓ :String=\"def\"": "let abc: String=\"def\"",
        "let abc↓ :Int=0": "let abc: Int=0",
        "let abc↓ :Int = 0": "let abc: Int = 0",
        "let abc↓:Int=0": "let abc: Int=0",
        "let abc↓:Int = 0": "let abc: Int = 0",
        "let abc↓:Enum=Enum.Value": "let abc: Enum=Enum.Value",
        "func abc(def↓:Void) {}": "func abc(def: Void) {}",
        "func abc(def↓:  Void) {}": "func abc(def: Void) {}",
        "func abc(def↓ :Void) {}": "func abc(def: Void) {}",
        "func abc(def↓ : Void) {}": "func abc(def: Void) {}",
        "func abc(def: Void, ghi↓ :Void) {}": "func abc(def: Void, ghi: Void) {}",
        "let abc = [Void↓:Void]()": "let abc = [Void: Void]()",
        "let abc = [Void↓ : Void]()": "let abc = [Void: Void]()",
        "let abc = [Void↓:  Void]()": "let abc = [Void: Void]()",
        "let abc = [Void↓ :  Void]()": "let abc = [Void: Void]()",
        "let abc = [1: [3↓ : 2], 3: 4]": "let abc = [1: [3: 2], 3: 4]",
        "let abc = [1: [3↓ : 2], 3↓:  4]": "let abc = [1: [3: 2], 3: 4]",
        "let abc: [String↓ : Int]": "let abc: [String: Int]",
        "let abc: [String↓:Int]": "let abc: [String: Int]",
        "func foo(bar: [String↓ : Int]) {}": "func foo(bar: [String: Int]) {}",
        "func foo(bar: [String↓:Int]) {}": "func foo(bar: [String: Int]) {}",
        "func foo() -> [String↓ : Int] { return [:] }":
            "func foo() -> [String: Int] { return [:] }",
        "func foo() -> [String↓:Int] { return [:] }":
            "func foo() -> [String: Int] { return [:] }",
        "let abc↓ : Any": "let abc: Any",
        "let abc: [Any↓ : Int]": "let abc: [Any: Int]",
        "let abc: [String↓ : Any]": "let abc: [String: Any]",
        "class Foo↓ : Bar {}": "class Foo: Bar {}",
        "class Foo↓:Bar {}": "class Foo: Bar {}",
        "class Foo<T>↓ : Bar {}": "class Foo<T>: Bar {}",
        "class Foo<T>↓:Bar {}": "class Foo<T>: Bar {}",
        "class Foo<T, U>↓:Bar {}": "class Foo<T, U>: Bar {}",
        "class Foo<T: Equatable>↓:Bar {}": "class Foo<T: Equatable>: Bar {}",
        "class Foo<T↓:Equatable> {}": "class Foo<T: Equatable> {}",
        "class Foo<T↓ : Equatable> {}": "class Foo<T: Equatable> {}",
        "object.method(x: 5, y↓ : \"string\")": "object.method(x: 5, y: \"string\")",
        "object.method(x↓:5, y: \"string\")": "object.method(x: 5, y: \"string\")",
        "object.method(x↓:  5, y: \"string\")": "object.method(x: 5, y: \"string\")",
        "func abc() { def(ghi↓:jkl) }": "func abc() { def(ghi: jkl) }",
        "func abc(def: Void) { ghi(jkl↓:mno) }": "func abc(def: Void) { ghi(jkl: mno) }",
        "class ABC { let def = ghi(jkl↓:mno) } }": "class ABC { let def = ghi(jkl: mno) } }",
        "func foo() { let dict = [1↓ : 1] }": "func foo() { let dict = [1: 1] }",
        """
        class Foo {
            #if false
            #else
                let bar = [\"key\"↓   : \"value\"]
            #endif
        }
        """:
            """
            class Foo {
                #if false
                #else
                    let bar = [\"key\": \"value\"]
                #endif
            }
            """,
        """
        switch foo {
        case .bar↓ : return baz
        }
        """:
            """
            switch foo {
            case .bar: return baz
            }
            """,
        "private var action↓:(() -> Void)?": "private var action: (() -> Void)?",
    ])
}
