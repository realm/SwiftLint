enum ImplicitOptionalInitializationRuleExamples { // swiftlint:disable:this type_name
    static let nonTriggeringExamples = #examples([
        // properties with body should be ignored
        """
            var foo: Int? {
              if bar != nil { }
              return 0
            }
            """,
        // properties with a closure call
        """
            var foo: Int? = {
              if bar != nil { }
              return 0
            }()
            """,
        "lazy var test: Int? = nil",
        "let myVar: String? = nil",
        "var myVar: Int? { nil }",
        "var x: Int? = 1",

        // never style
        "private var myVar: Int? = nil".configuration(["style": "never"]),
        "var myVar: Optional<Int> = nil".configuration(["style": "never"]),
        "var myVar: Int? { nil }, myOtherVar: Int? = nil".configuration(["style": "never"]),
        """
            var myVar: String? = nil {
              didSet { print("didSet") }
            }
            """.configuration(["style": "never"]),
        """
            func funcName() {
                var myVar: String? = nil
            }
            """.configuration(["style": "never"]),
        "var x: Int? = nil // comment".configuration(["style": "never"]),  // with comment after
        """
            @Wrapper("name")
            var flag: Bool?
            """.configuration([
                "style": "never",
                "ignore_attributes": ["Wrapper"],
            ]),

        // always style
        "public var myVar: Int?".configuration(["style": "always"]),
        "var myVar: Optional<Int>".configuration(["style": "always"]),
        """
            @Wrapper("name")
            var flag: Bool? = nil
            """.configuration([
                "style": "always",
                "ignore_attributes": ["Wrapper"],
            ]),
        "var myVar: Int? { nil }, myOtherVar: Int?".configuration(["style": "always"]),
        """
            var myVar: String? {
              didSet { print("didSet") }
            }
            """.configuration(["style": "always"]),
        """
            func funcName() {
              var myVar: String?
            }
            """.configuration(["style": "always"]),
        "var x: Int? // comment".configuration(["style": "always"]),  // with comment after
    ])

    static let triggeringExamples = #examples([
        // never style
        "var ↓myVar: Int? ".configuration(["style": "never"]),
        "var ↓myVar: Optional<Int> ".configuration(["style": "never"]),
        "var myVar: Int? = nil, ↓myOtherVar: Int? ".configuration(["style": "never"]),
        """
            var ↓myVar: String? {
              didSet { print("didSet") }
            }
            """.configuration(["style": "never"]),
        """
            func funcName() {
              var ↓myVar: String?
            }
            """.configuration(["style": "never"]),
        """
            @Wrapper("name")
            var ↓flag: Bool?
            """.configuration([
                "style": "never",
                "ignore_attributes": ["State"],
            ]),

        // always style
        "var ↓myVar: Int? = nil".configuration(["style": "always"]),
        "var ↓myVar: Optional<Int> = nil".configuration(["style": "always"]),
        """
            @Wrapper("name")
            var ↓flag: Bool? = nil
            """.configuration([
                "style": "always",
                "ignore_attributes": ["State"],
            ]),
        "var myVar: Int?, ↓myOtherVar: Int? = nil".configuration(["style": "always"]),
        """
            var ↓myVar: String? = nil {
              didSet { print("didSet") }
            }
            """.configuration(["style": "always"]),
        """
            func funcName() {
                var ↓myVar: String? = nil
            }
            """.configuration(["style": "always"]),
    ])

    static let corrections = #examplesDictionary([
        // never style
        """
            @Wrapper("name")
            var flag: Bool?
            """.configuration([
                "style": "never",
                "ignore_attributes": ["Wrapper"],
            ]):

                """
                @Wrapper("name")
                var flag: Bool?
                """,
        "var ↓myVar: Int? // comment".configuration(["style": "never"]):
            "var myVar: Int? = nil // comment",
        "var ↓myVar: Optional<Int> // comment".configuration(["style": "never"]):
            "var myVar: Optional<Int> = nil // comment",
        """
            var ↓myVar: String? {
              didSet { print("didSet") }
            }
            """.configuration(["style": "never"]):

                """
                var myVar: String? = nil {
                  didSet { print("didSet") }
                }
                """,
        """
            func funcName() {
              var ↓myVar: String?
            }
            """.configuration(["style": "never"]):
            """
            func funcName() {
              var myVar: String? = nil
            }
            """,

        """
            @Wrapper("name")
            var flag: Bool? = nil
            """.configuration([
                "style": "always",
                "ignore_attributes": ["Wrapper"],
            ]):

                """
                @Wrapper("name")
                var flag: Bool? = nil
                """,
        "var ↓myVar: Int? = nil // comment".configuration(["style": "always"]):
            "var myVar: Int? // comment",
        "var ↓myVar: Optional<Int> = nil // comment".configuration(["style": "always"]):
            "var myVar: Optional<Int> // comment",
        """
            var ↓myVar: String? = nil {
              didSet { print("didSet") }
            }
            """.configuration(["style": "always"]):

                """
                var myVar: String? {
                  didSet { print("didSet") }
                }
                """,
        """
            func funcName() {
                var ↓myVar: String? = nil
            }
            """.configuration(["style": "always"]):

                """
                func funcName() {
                    var myVar: String?
                }
                """,
    ])
}
