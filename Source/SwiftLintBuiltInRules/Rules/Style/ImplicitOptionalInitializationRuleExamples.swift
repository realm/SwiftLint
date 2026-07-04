import SwiftLintCore

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
        "private var myVar: Int? = nil".asExample(configuration: ["style": "never"]),
        "var myVar: Optional<Int> = nil".asExample(configuration: ["style": "never"]),
        "var myVar: Int? { nil }, myOtherVar: Int? = nil".asExample(configuration: ["style": "never"]),
        """
            var myVar: String? = nil {
              didSet { print("didSet") }
            }
            """.asExample(configuration: ["style": "never"]),
        """
            func funcName() {
                var myVar: String? = nil
            }
            """.asExample(configuration: ["style": "never"]),
        "var x: Int? = nil // comment".asExample(configuration: ["style": "never"]),  // with comment after
        """
            @Wrapper("name")
            var flag: Bool?
            """.asExample(configuration: [
                "style": "never",
                "ignore_attributes": ["Wrapper"],
            ]),

        // always style
        "public var myVar: Int?".asExample(configuration: ["style": "always"]),
        "var myVar: Optional<Int>".asExample(configuration: ["style": "always"]),
        """
            @Wrapper("name")
            var flag: Bool? = nil
            """.asExample(configuration: [
                "style": "always",
                "ignore_attributes": ["Wrapper"],
            ]),
        "var myVar: Int? { nil }, myOtherVar: Int?".asExample(configuration: ["style": "always"]),
        """
            var myVar: String? {
              didSet { print("didSet") }
            }
            """.asExample(configuration: ["style": "always"]),
        """
            func funcName() {
              var myVar: String?
            }
            """.asExample(configuration: ["style": "always"]),
        "var x: Int? // comment".asExample(configuration: ["style": "always"]),  // with comment after
    ])

    static let triggeringExamples = #examples([
        // never style
        "var ↓myVar: Int? ".asExample(configuration: ["style": "never"]),
        "var ↓myVar: Optional<Int> ".asExample(configuration: ["style": "never"]),
        "var myVar: Int? = nil, ↓myOtherVar: Int? ".asExample(configuration: ["style": "never"]),
        """
            var ↓myVar: String? {
              didSet { print("didSet") }
            }
            """.asExample(configuration: ["style": "never"]),
        """
            func funcName() {
              var ↓myVar: String?
            }
            """.asExample(configuration: ["style": "never"]),
        """
            @Wrapper("name")
            var ↓flag: Bool?
            """.asExample(configuration: [
                "style": "never",
                "ignore_attributes": ["State"],
            ]),

        // always style
        "var ↓myVar: Int? = nil".asExample(configuration: ["style": "always"]),
        "var ↓myVar: Optional<Int> = nil".asExample(configuration: ["style": "always"]),
        """
            @Wrapper("name")
            var ↓flag: Bool? = nil
            """.asExample(configuration: [
                "style": "always",
                "ignore_attributes": ["State"],
            ]),
        "var myVar: Int?, ↓myOtherVar: Int? = nil".asExample(configuration: ["style": "always"]),
        """
            var ↓myVar: String? = nil {
              didSet { print("didSet") }
            }
            """.asExample(configuration: ["style": "always"]),
        """
            func funcName() {
                var ↓myVar: String? = nil
            }
            """.asExample(configuration: ["style": "always"]),
    ])

    static let corrections = #corrections([
        // never style
        """
            @Wrapper("name")
            var flag: Bool?
            """.asExample(configuration: [
                "style": "never",
                "ignore_attributes": ["Wrapper"],
            ]):

                """
                @Wrapper("name")
                var flag: Bool?
                """,
        "var ↓myVar: Int? // comment".asExample(configuration: ["style": "never"]):
            "var myVar: Int? = nil // comment",
        "var ↓myVar: Optional<Int> // comment".asExample(configuration: ["style": "never"]):
            "var myVar: Optional<Int> = nil // comment",
        """
            var ↓myVar: String? {
              didSet { print("didSet") }
            }
            """.asExample(configuration: ["style": "never"]):

                """
                var myVar: String? = nil {
                  didSet { print("didSet") }
                }
                """,
        """
            func funcName() {
              var ↓myVar: String?
            }
            """.asExample(configuration: ["style": "never"]):
            """
            func funcName() {
              var myVar: String? = nil
            }
            """,

        """
            @Wrapper("name")
            var flag: Bool? = nil
            """.asExample(configuration: [
                "style": "always",
                "ignore_attributes": ["Wrapper"],
            ]):

                """
                @Wrapper("name")
                var flag: Bool? = nil
                """,
        "var ↓myVar: Int? = nil // comment".asExample(configuration: ["style": "always"]):
            "var myVar: Int? // comment",
        "var ↓myVar: Optional<Int> = nil // comment".asExample(configuration: ["style": "always"]):
            "var myVar: Optional<Int> // comment",
        """
            var ↓myVar: String? = nil {
              didSet { print("didSet") }
            }
            """.asExample(configuration: ["style": "always"]):

                """
                var myVar: String? {
                  didSet { print("didSet") }
                }
                """,
        """
            func funcName() {
                var ↓myVar: String? = nil
            }
            """.asExample(configuration: ["style": "always"]):

                """
                func funcName() {
                    var myVar: String?
                }
                """,
    ])
}
