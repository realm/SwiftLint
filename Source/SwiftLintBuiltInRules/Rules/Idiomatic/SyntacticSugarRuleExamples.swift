internal enum SyntacticSugarRuleExamples {
    static let nonTriggering = [
        Example("let x: [Int]"),
        Example("let x: [Int: String]"),
        Example("let x: Int?"),
        Example("func x(a: [Int], b: Int) -> [Int: Any]"),
        Example("let x: Int!"),
        Example("""
        extension Array {
          func x() { }
        }
        """),
        Example("""
        extension Dictionary {
          func x() { }
        }
        """),
        Example("let x: CustomArray<String>"),
        Example("var currentIndex: Array<OnboardingPage>.Index?"),
        Example("func x(a: [Int], b: Int) -> Array<Int>.Index"),
        Example("unsafeBitCast(nonOptionalT, to: Optional<T>.self)"),
        Example("unsafeBitCast(someType, to: Swift.Array<T>.self)"),
        Example("IndexingIterator<Array<Dictionary<String, AnyObject>>>.self"),
        Example("let y = Optional<String>.Type"),

        Example("type is Optional<String>.Type"),
        Example("let x: Foo.Optional<String>"),

        Example("let x = case Optional<Any>.none = obj"),
        Example("let a = Swift.Optional<String?>.none"),
        Example("func f() -> [Array<Int>.Index] { [Array<Int>.Index]() }", excludeFromDocumentation: true)
    ]

    static let triggering = [
        Example("let x: ↓Array<String>"),
        Example("let x: ↓Dictionary<Int, String>"),
        Example("let x: ↓Optional<Int>"),
        Example("let x: ↓Swift.Array<String>"),

        Example("func x(a: ↓Array<Int>, b: Int) -> [Int: Any]"),
        Example("func x(a: ↓Swift.Array<Int>, b: Int) -> [Int: Any]"),

        Example("func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>"),
        Example("let x = y as? ↓Array<[String: Any]>"),
        Example("let x = Box<Array<T>>()"),
        Example("func x() -> Box<↓Array<T>>"),
        Example("func x() -> ↓Dictionary<String, Any>?"),

        Example("typealias Document = ↓Dictionary<String, T?>"),
        Example("func x(_ y: inout ↓Array<T>)"),
        Example("let x:↓Dictionary<String, ↓Dictionary<Int, Int>>"),
        Example("func x() -> Any { return ↓Dictionary<Int, String>()}"),

        Example("let x = ↓Array<String>.array(of: object)"),
        Example("let x = ↓Swift.Array<String>.array(of: object)"),

        Example("""
        @_specialize(where S == ↓Array<Character>)
        public init<S: Sequence>(_ elements: S)
        """),

        Example("""
        let dict: [String: Any] = [:]
        _ = dict["key"] as? ↓Optional<String?> ?? Optional<String?>.none
        """)
    ]

    static let corrections = [
        Example("let x: Array<String>"): Example("let x: [String]"),
        Example("let x: Array< String >"): Example("let x: [String]"),
        Example("let x: Dictionary<Int, String>"): Example("let x: [Int: String]"),
        Example("let x: Optional<Int>"): Example("let x: Int?"),
        Example("let x: Optional< Int >"): Example("let x: Int?"),

        Example("let x: Dictionary<Int , String>"): Example("let x: [Int: String]"),
        Example("let x: Swift.Optional<String>"): Example("let x: String?"),
        Example("let x:↓Dictionary<String, ↓Dictionary<Int, Int>>"): Example("let x:[String: [Int: Int]]"),
        Example("let x:↓Dictionary<↓Dictionary<Int, Int>, String>"): Example("let x:[[Int: Int]: String]"),
        Example("let x:↓Dictionary<↓Dictionary<↓Dictionary<Int, Int>, Int>, String>"):
            Example("let x:[[[Int: Int]: Int]: String]"),
        Example("let x:↓Array<↓Dictionary<Int, Int>>"): Example("let x:[[Int: Int]]"),
        Example("let x:↓Optional<↓Dictionary<Int, Int>>"): Example("let x:[Int: Int]?")
    ]
}
