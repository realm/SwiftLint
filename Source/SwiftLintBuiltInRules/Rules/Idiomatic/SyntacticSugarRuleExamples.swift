internal enum SyntacticSugarRuleExamples {
    static let nonTriggering = #examples([
        "let x: [Int]",
        "let x: [Int: String]",
        "let x: Int?",
        "func x(a: [Int], b: Int) -> [Int: Any]",
        "let x: Int!",
        """
        extension Array {
          func x() { }
        }
        """,
        """
        extension Dictionary {
          func x() { }
        }
        """,
        "let x: CustomArray<String>",
        "var currentIndex: Array<OnboardingPage>.Index?",
        "func x(a: [Int], b: Int) -> Array<Int>.Index",
        "unsafeBitCast(nonOptionalT, to: Optional<T>.self)",
        "unsafeBitCast(someType, to: Swift.Array<T>.self)",
        "IndexingIterator<Array<Dictionary<String, AnyObject>>>.self",
        "let y = Optional<String>.Type",

        "type is Optional<String>.Type",
        "let x: Foo.Optional<String>",

        "let x = case Optional<Any>.none = obj",
        "let a = Swift.Optional<String?>.none",
        "func f() -> [Array<Int>.Index] { [Array<Int>.Index]() }".excludeFromDocumentation(),
    ])

    static let triggering = #examples([
        "let x: ↓Array<String>",
        "let x: ↓Dictionary<Int, String>",
        "let x: ↓Optional<Int>",
        "let x: ↓Swift.Array<String>",

        "func x(a: ↓Array<Int>, b: Int) -> [Int: Any]",
        "func x(a: ↓Swift.Array<Int>, b: Int) -> [Int: Any]",

        "func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>",
        "let x = y as? ↓Array<[String: Any]>",
        "let x = Box<Array<T>>()",
        "func x() -> Box<↓Array<T>>",
        "func x() -> ↓Dictionary<String, Any>?",

        "typealias Document = ↓Dictionary<String, T?>",
        "func x(_ y: inout ↓Array<T>)",
        "let x:↓Dictionary<String, ↓Dictionary<Int, Int>>",
        "func x() -> Any { return ↓Dictionary<Int, String>()}",

        "let x = ↓Array<String>.array(of: object)",
        "let x = ↓Swift.Array<String>.array(of: object)",

        """
        @_specialize(where S == ↓Array<Character>)
        public init<S: Sequence>(_ elements: S)
        """,

        """
        let dict: [String: Any] = [:]
        _ = dict["key"] as? ↓Optional<String?> ?? Optional<String?>.none
        """,
    ])

    static let corrections = #corrections([
        "let x: Array<String>": "let x: [String]",
        "let x: Array< String >": "let x: [String]",
        "let x: Dictionary<Int, String>": "let x: [Int: String]",
        "let x: Optional<Int>": "let x: Int?",
        "let x: Optional< Int >": "let x: Int?",
        "func f() -> Optional<any Foo> {}": "func f() -> (any Foo)? {}",
        "func f() -> Optional<some Foo> {}": "func f() -> (some Foo)? {}",

        "let x: Dictionary<Int , String>": "let x: [Int: String]",
        "let x: Swift.Optional<String>": "let x: String?",
        "let x:↓Dictionary<String, ↓Dictionary<Int, Int>>": "let x:[String: [Int: Int]]",
        "let x:↓Dictionary<↓Dictionary<Int, Int>, String>": "let x:[[Int: Int]: String]",
        "let x:↓Dictionary<↓Dictionary<↓Dictionary<Int, Int>, Int>, String>":
            "let x:[[[Int: Int]: Int]: String]",
        "let x:↓Array<↓Dictionary<Int, Int>>": "let x:[[Int: Int]]",
        "let x:↓Optional<↓Dictionary<Int, Int>>": "let x:[Int: Int]?",
    ])
}
