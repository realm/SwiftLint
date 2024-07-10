struct ImplicitReturnRuleExamples {
    struct ClosureExamples {
        static let nonTriggeringExamples = [
            Example("foo.map { $0 + 1 }"),
            Example("foo.map({ $0 + 1 })"),
            Example("foo.map { value in value + 1 }"),
            Example("""
            [1, 2].first(where: {
                true
            })
            """),
        ]

        static let triggeringExamples = [
            Example("""
            foo.map { value in
                ↓return value + 1
            }
            """),
            Example("""
            foo.map {
                ↓return $0 + 1
            }
            """),
            Example("foo.map({ ↓return $0 + 1})"),
            Example("""
            [1, 2].first(where: {
                ↓return true
            })
            """),
        ]

        static let corrections = [
            Example("""
            foo.map { value in
                // Important comment
                return value + 1
            }
            """): Example("""
                foo.map { value in
                    // Important comment
                    value + 1
                }
                """),
            Example("""
            foo.map {
                return $0 + 1
            }
            """): Example("""
                foo.map {
                    $0 + 1
                }
                """),
            Example("foo.map({ return $0 + 1 })"): Example("foo.map({ $0 + 1 })"),
            Example("""
            [1, 2].first(where: {
                return true
            })
            """): Example("""
                [1, 2].first(where: {
                    true
                })
                """),
        ]
    }

    struct FunctionExamples {
        static let nonTriggeringExamples = [
            Example("""
            func foo() -> Int {
                0
            }
            """),
            Example("""
            class Foo {
                func foo() -> Int { 0 }
            }
            """),
            Example("""
            func fetch() -> Data? {
                do {
                    return try loadData()
                } catch {
                    return nil
                }
            }
            """),
            Example("""
            func f() -> Int {
                let i = 4
                return i
            }
            """),
            Example("""
            func f() -> Int {
                return 3
                let i = 2
            }
            """),
            Example("""
            func f() -> Int {
                return g()
                func g() -> Int { 4 }
            }
            """),
        ]

        static let triggeringExamples = [
            Example("""
            func foo() -> Int {
                ↓return 0
            }
            """),
            Example("""
            class Foo {
                func foo() -> Int { ↓return 0 }
            }
            """),
            Example("""
            func f() { ↓return }
            """),
        ]

        static let corrections = [
            Example("""
            func foo() -> Int {
                return 0
            }
            """): Example("""
                func foo() -> Int {
                    0
                }
                """),
            Example("""
            class Foo {
                func foo() -> Int {
                    return 0
                }
            }
            """): Example("""
                class Foo {
                    func foo() -> Int {
                        0
                    }
                }
                """),
            Example("""
            func f() {
                // Comment
                ↓return
                // Another comment
            }
            """): Example("""
                func f() {
                    // Comment
                    \("")
                    // Another comment
                }
                """),
        ]
    }

    struct GetterExamples {
        static let nonTriggeringExamples = [
            Example("var foo: Bool { true }"),
            Example("""
            class Foo {
                var bar: Int {
                    get {
                        0
                    }
                }
            }
            """),
            Example("""
            class Foo {
                static var bar: Int {
                    0
                }
            }
            """),
        ]

        static let triggeringExamples = [
            Example("var foo: Bool { ↓return true }"),
            Example("""
            class Foo {
                var bar: Int {
                    get {
                        ↓return 0
                    }
                }
            }
            """),
            Example("""
            class Foo {
                static var bar: Int {
                    ↓return 0
                }
            }
            """),
        ]

        static let corrections = [
            Example("var foo: Bool { return true }"): Example("var foo: Bool { true }"),
            Example("""
            class Foo {
                var bar: Int {
                    get {
                        return 0
                    }
                }
            }
            """): Example("""
                class Foo {
                    var bar: Int {
                        get {
                            0
                        }
                    }
                }
                """),
        ]
    }

    struct InitializerExamples {
        static let nonTriggeringExamples = [
            Example("""
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
            """),
            Example("""
            class C {
                init?() {
                    let i = 1
                    return nil
                }
            }
            """),
        ]

        static let triggeringExamples = [
            Example("""
            class C {
                init() {
                    ↓return
                }
            }
            """),
            Example("""
            class C {
                init?() {
                    ↓return nil
                }
            }
            """),
        ]

        static let corrections = [
            Example("""
            class C {
                init() {
                    ↓return
                }
            }
            """): Example("""
                class C {
                    init() {
                        \("")
                    }
                }
                """),
            Example("""
            class C {
                init?() {
                    ↓return nil
                }
            }
            """): Example("""
                class C {
                    init?() {
                        nil
                    }
                }
                """),
        ]
    }

    struct SubscriptExamples {
        static let nonTriggeringExamples = [
            Example("""
            class C {
                subscript(i: Int) -> Int {
                    let res = i
                    return res
                }
            }
            """),
        ]

        static let triggeringExamples = [
            Example("""
            class C {
                subscript(i: Int) -> Int {
                    ↓return i
                }
            }
            """),
        ]

        static let corrections = [
            Example("""
            class C {
                subscript(i: Int) -> Int {
                    ↓return i
                }
            }
            """): Example("""
                class C {
                    subscript(i: Int) -> Int {
                        i
                    }
                }
                """),
        ]
    }

    struct MixedExamples {
        static let corrections = [
            Example("""
                func foo() -> Int {
                    ↓return [1, 2].first(where: {
                        ↓return true
                    })
                }
                """): Example("""
                func foo() -> Int {
                    [1, 2].first(where: {
                        true
                    })
                }
                """),
        ]
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
