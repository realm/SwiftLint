struct ImplicitReturnRuleExamples {
    struct ClosureExamples {
        static let nonTriggeringExamples = #examples([
            "foo.map { $0 + 1 }",
            "foo.map({ $0 + 1 })",
            "foo.map { value in value + 1 }",
            """
            [1, 2].first(where: {
                true
            })
            """,
        ])

        static let triggeringExamples = #examples([
            """
            foo.map { value in
                ↓return value + 1
            }
            """,
            """
            foo.map {
                ↓return $0 + 1
            }
            """,
            "foo.map({ ↓return $0 + 1})",
            """
            [1, 2].first(where: {
                ↓return true
            })
            """,
        ])

        static let corrections = #examplesDictionary([
            """
            foo.map { value in
                // Important comment
                return value + 1
            }
            """: """
                foo.map { value in
                    // Important comment
                    value + 1
                }
                """,
            """
            foo.map {
                return $0 + 1
            }
            """: """
                foo.map {
                    $0 + 1
                }
                """,
            "foo.map({ return $0 + 1 })": "foo.map({ $0 + 1 })",
            """
            [1, 2].first(where: {
                return true
            })
            """: """
                [1, 2].first(where: {
                    true
                })
                """,
        ])
    }

    struct FunctionExamples {
        static let nonTriggeringExamples = #examples([
            """
            func foo() -> Int {
                0
            }
            """,
            """
            class Foo {
                func foo() -> Int { 0 }
            }
            """,
            """
            func fetch() -> Data? {
                do {
                    return try loadData()
                } catch {
                    return nil
                }
            }
            """,
            """
            func f() -> Int {
                let i = 4
                return i
            }
            """,
            """
            func f() -> Int {
                return 3
                let i = 2
            }
            """,
            """
            func f() -> Int {
                return g()
                func g() -> Int { 4 }
            }
            """,
        ])

        static let triggeringExamples = #examples([
            """
            func foo() -> Int {
                ↓return 0
            }
            """,
            """
            class Foo {
                func foo() -> Int { ↓return 0 }
            }
            """,
            """
            func f() { ↓return }
            """,
        ])

        static let corrections = #examplesDictionary([
            """
            func foo() -> Int {
                return 0
            }
            """: """
                func foo() -> Int {
                    0
                }
                """,
            """
            class Foo {
                func foo() -> Int {
                    return 0
                }
            }
            """: """
                class Foo {
                    func foo() -> Int {
                        0
                    }
                }
                """,
            """
            func f() {
                // Comment
                ↓return
                // Another comment
            }
            """: """
                func f() {
                    // Comment
                    \("")
                    // Another comment
                }
                """,
        ])
    }

    struct GetterExamples {
        static let nonTriggeringExamples = #examples([
            "var foo: Bool { true }",
            """
            class Foo {
                var bar: Int {
                    get {
                        0
                    }
                }
            }
            """,
            """
            class Foo {
                static var bar: Int {
                    0
                }
            }
            """,
        ])

        static let triggeringExamples = #examples([
            "var foo: Bool { ↓return true }",
            """
            class Foo {
                var bar: Int {
                    get {
                        ↓return 0
                    }
                }
            }
            """,
            """
            class Foo {
                static var bar: Int {
                    ↓return 0
                }
            }
            """,
        ])

        static let corrections = #examplesDictionary([
            "var foo: Bool { return true }": "var foo: Bool { true }",
            """
            class Foo {
                var bar: Int {
                    get {
                        return 0
                    }
                }
            }
            """: """
                class Foo {
                    var bar: Int {
                        get {
                            0
                        }
                    }
                }
                """,
        ])
    }

    struct InitializerExamples {
        static let nonTriggeringExamples = #examples([
            """
            class C {
                let i: Int
                init(i: Int) {
                    if i < 3 {
                        self.i = 1
                        return
                    }
                    self.i = 2
                }
            }
            """,
            """
            class C {
                init?() {
                    let i = 1
                    return nil
                }
            }
            """,
        ])

        static let triggeringExamples = #examples([
            """
            class C {
                init() {
                    ↓return
                }
            }
            """,
            """
            class C {
                init?() {
                    ↓return nil
                }
            }
            """,
        ])

        static let corrections = #examplesDictionary([
            """
            class C {
                init() {
                    ↓return
                }
            }
            """: """
                class C {
                    init() {
                        \("")
                    }
                }
                """,
            """
            class C {
                init?() {
                    ↓return nil
                }
            }
            """: """
                class C {
                    init?() {
                        nil
                    }
                }
                """,
        ])
    }

    struct SubscriptExamples {
        static let nonTriggeringExamples = #examples([
            """
            class C {
                subscript(i: Int) -> Int {
                    let res = i
                    return res
                }
            }
            """,
        ])

        static let triggeringExamples = #examples([
            """
            class C {
                subscript(i: Int) -> Int {
                    ↓return i
                }
            }
            """,
        ])

        static let corrections = #examplesDictionary([
            """
            class C {
                subscript(i: Int) -> Int {
                    ↓return i
                }
            }
            """: """
                class C {
                    subscript(i: Int) -> Int {
                        i
                    }
                }
                """,
        ])
    }

    struct MixedExamples {
        static let corrections = #examplesDictionary([
            """
                func foo() -> Int {
                    ↓return [1, 2].first(where: {
                        ↓return true
                    })
                }
                """: """
                func foo() -> Int {
                    [1, 2].first(where: {
                        true
                    })
                }
                """,
        ])
    }

    static let nonTriggeringExamples =
        ClosureExamples.nonTriggeringExamples +
        FunctionExamples.nonTriggeringExamples +
        GetterExamples.nonTriggeringExamples +
        InitializerExamples.nonTriggeringExamples +
        SubscriptExamples.nonTriggeringExamples

    static let triggeringExamples =
        ClosureExamples.triggeringExamples +
        FunctionExamples.triggeringExamples +
        GetterExamples.triggeringExamples +
        InitializerExamples.triggeringExamples +
        SubscriptExamples.triggeringExamples

    static var corrections: [Example: Example] {
        [
            ClosureExamples.corrections,
            FunctionExamples.corrections,
            GetterExamples.corrections,
            InitializerExamples.corrections,
            SubscriptExamples.corrections,
            MixedExamples.corrections,
        ]
        .reduce(into: [:]) { result, element in
            result.merge(element) { _, _ in
                preconditionFailure("Duplicate correction in implicit return rule examples.")
            }
        }
    }
}
