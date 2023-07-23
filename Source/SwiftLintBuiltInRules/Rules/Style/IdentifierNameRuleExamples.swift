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
                """),
        Example("""
                class Foo {
                    let operationQueue: OperationQueue = {
                        let q = OperationQueue()
                        q.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
                        return q
                    }()
                }
                """,
                configuration: ["ignore_min_length_for_short_closure_content": true],
                excludeFromDocumentation: true),
        Example(
            "private func h1(_ text: String) -> String { \"# \\(text)\" }",
            configuration: ["evaluate_func_name_length": false],
            excludeFromDocumentation: true),
        Example(
            """
            func hasAccessibilityElementChildrenIgnoreModifier(in file: SwiftLintFile) -> Bool { false }
            """,
            configuration: ["evaluate_func_name_length": false],
            excludeFromDocumentation: true)
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
            "↓func IsOperator(name: String) -> Bool",
            configuration: ["validates_start_with_lowercase": "warning"],
            excludeFromDocumentation: true
        ),
        Example(
            "enum Foo { case ↓MyEnum }",
            configuration: ["validates_start_with_lowercase": "error"],
            excludeFromDocumentation: true),
        Example("""
                class Foo {
                    let operationQueue: OperationQueue = {
                        ↓let q = OperationQueue()
                        q.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
                        return q
                    }()
                }
                """,
                excludeFromDocumentation: true),

        // previously passed, now error
        Example("private ↓func h1(_ text: String) -> String { \"# \\(text)\" }"),
        Example("↓func firstConfigurationFileInParentDirectories() -> Path? {}"),
        Example(
            """
            ↓func bodyLineCountIgnoringCommentsAndWhitespace(
                leftBraceLine: Int, rightBraceLine: Int
            ) -> Int { 0 }
            """),
        Example(
            """
            ↓func hasAccessibilityElementChildrenIgnoreModifier(in file: SwiftLintFile) -> Bool { false }
            """)
    ]
}
