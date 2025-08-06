enum ImplicitOptionalInitializationRuleExamples {
    static let nonTriggeringExamples = [
        Example(  // properties with body should be ignored
            """
            var foo: Int? {
              if bar != nil { }
              return 0
            }
            """),
        Example(  // properties with a closure call
            """
            var foo: Int? = {
              if bar != nil { }
              return 0
            }()
            """
        ),
        Example("lazy var test: Int? = nil"),  // lazy variables need to be initialized
        Example("let myVar: String? = nil"),  // let variables need to be initialized
        Example("var myVar: Int? { nil }"),  // computed properties should be ignored
        Example("var x: Int? = 1"),  // initialized with a value

        // never style
        Example("private var myVar: Int? = nil", configuration: ["style": "never"]),
        Example("var myVar: Optional<Int> = nil", configuration: ["style": "never"]),
        Example(
            "var myVar: Int? { nil }, myOtherVar: Int? = nil", configuration: ["style": "never"]
        ),
        Example(
            """
            var myVar: String? = nil {
              didSet { print("didSet") }
            }
            """, configuration: ["style": "never"]),
        Example(
            """
            func funcName() {
                var myVar: String? = nil
            }
            """, configuration: ["style": "never"]),

        // always style
        Example("public var myVar: Int?", configuration: ["style": "always"]),
        Example("var myVar: Optional<Int>", configuration: ["style": "always"]),
        Example(
            "var myVar: Int? { nil }, myOtherVar: Int?", configuration: ["style": "always"]),
        Example(
            """
            var myVar: String? {
              didSet { print("didSet") }
            }
            """, configuration: ["style": "always"]),
        Example(
            """
            func funcName() {
              var myVar: String?
            }
            """, configuration: ["style": "always"]),
    ]

    static let triggeringExamples = [
        // never style
        Example("var ↓myVar: Int? ", configuration: ["style": "never"]),
        Example("var ↓myVar: Optional<Int> ", configuration: ["style": "never"]),
        Example("var myVar: Int? = nil, ↓myOtherVar: Int? ", configuration: ["style": "never"]),
        Example(
            """
            var ↓myVar: String? {
              didSet { print("didSet") }
            }
            """, configuration: ["style": "never"]),
        Example(
            """
            func funcName() {
              var ↓myVar: String?
            }
            """, configuration: ["style": "never"]
        ),

        // always style
        Example("var ↓myVar: Int? = nil", configuration: ["style": "always"]),
        Example("var ↓myVar: Optional<Int> = nil", configuration: ["style": "always"]),
        Example("var myVar: Int?, ↓myOtherVar: Int? = nil", configuration: ["style": "always"]),
        Example(
            """
            var ↓myVar: String? = nil {
              didSet { print("didSet") }
            }
            """, configuration: ["style": "always"]),
        Example(
            """
            func funcName() {
                var ↓myVar: String? = nil
            }
            """, configuration: ["style": "always"]),
    ]

    static let corrections = [
        // never style
        Example("var ↓myVar: Int? ", configuration: ["style": "never"]):
            Example("var myVar: Int? = nil "),
        Example("var ↓myVar: Optional<Int> ", configuration: ["style": "never"]):
            Example("var myVar: Optional<Int> = nil "),
        Example(
            """
            var ↓myVar: String? {
              didSet { print("didSet") }
            }
            """, configuration: ["style": "never"]):
            Example(
                """
                var myVar: String? = nil {
                  didSet { print("didSet") }
                }
                """),
        Example(
            """
            func funcName() {
              var ↓myVar: String?
            }
            """, configuration: ["style": "never"]
        ): Example(
            """
            func funcName() {
              var myVar: String? = nil
            }
            """),

        Example("var ↓myVar: Int? = nil", configuration: ["style": "always"]):
            Example("var myVar: Int?"),
        Example("var ↓myVar: Optional<Int> = nil", configuration: ["style": "always"]):
            Example("var myVar: Optional<Int>"),
        Example(
            """
            var ↓myVar: String? = nil {
              didSet { print("didSet") }
            }
            """, configuration: ["style": "always"]):
            Example(
                """
                var myVar: String? {
                  didSet { print("didSet") }
                }
                """),
        Example(
            """
            func funcName() {
                var ↓myVar: String? = nil
            }
            """, configuration: ["style": "always"]):
            Example(
                """
                func funcName() {
                    var myVar: String?
                }
                """),
    ]
}
