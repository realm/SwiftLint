// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
internal struct ExplicitReturnRuleExamples {
    private static let closureConfig: [String: any Sendable] = [
        "included": ["closure", "function", "getter", "subscript", "initializer"],
    ]

    internal struct ClosureExamples {
        static let nonTriggeringExamples = [
            Example("""
            foo.map {
                return $0 + 1
            }
            """, configuration: closureConfig),
            Example("""
            foo.map({
                return $0 + 1
            })
            """, configuration: closureConfig),
            Example("""
            foo.map { value in
                return value + 1
            }
            """, configuration: closureConfig),
            Example("""
            [1, 2].first(where: {
                return true
            })
            """, configuration: closureConfig),
            Example("""
            [1, 2].first(where: {
                bar($0)
                return true
            })
            """, configuration: closureConfig),
            Example("""
            runOn(.main, {
                controller?.present(alert, animated: true, completion: nil)
            })
            """, configuration: closureConfig),
            Example("""
            foo.bar(failure: { error in
                cont.resume(throwing: error)
            })
            """, configuration: closureConfig),
            Example("""
            foo.map {
                someFunc($0)
            }
            """, configuration: closureConfig),
            Example("""
            foo.map {
                try someFunc($0)
            }
            """, configuration: closureConfig),
            Example("""
            foo.map {
                await someFunc($0)
            }
            """, configuration: closureConfig),
        ]

        static let triggeringExamples = [
            Example("""
            foo.map { value in
                ↓value + 1
            }
            """, configuration: closureConfig),
            Example("""
            foo.map {
                ↓$0 + 1
            }
            """, configuration: closureConfig),
            Example("foo.map({ ↓$0 + 1 })", configuration: closureConfig),
            Example("""
            [1, 2].first(where: {
                ↓true
            })
            """, configuration: closureConfig),
        ]

        static let corrections: [Example: Example] = [
            Example("""
            foo.map { value in
                // Important comment
                value + 1
            }
            """, configuration: closureConfig): Example("""
                foo.map { value in
                    // Important comment
                    return value + 1
                }
                """),
            Example("""
            foo.map {
                $0 + 1
            }
            """, configuration: closureConfig): Example("""
                foo.map {
                    return $0 + 1
                }
                """),
            Example("foo.map({ $0 + 1 })", configuration: closureConfig):
                Example("foo.map({ return $0 + 1 })"),
            Example("""
            [1, 2].first(where: {
                true
            })
            """, configuration: closureConfig): Example("""
                [1, 2].first(where: {
                    return true
                })
                """),
        ]
    }

    struct FunctionExamples {
        static let nonTriggeringExamples = [
            Example("""
            func foo() -> Int {
                return 0
            }
            """),
            Example("""
            class Foo {
                func foo() -> Int { return 0 }
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
                func g() -> Int { return 4 }
            }
            """),
            Example("""
            func foo() {
                bar()
            }
            """),
            Example("""
            func foo() -> Void {
                bar()
            }
            """),
            Example("""
            func foo() -> () {
                bar()
            }
            """),
            Example("""
            func foo() -> Never {
                fatalError()
            }
            """),
            Example("""
            func foo() throws {
                throw Foo.bar
            }
            """),
            Example("""
            func foo() -> Int {
                bar()
                return 0
            }
            """),
        ]

        static let triggeringExamples = [
            Example("""
            func foo() -> Int {
                ↓0
            }
            """),
            Example("""
            class Foo {
                func foo() -> Int { ↓0 }
            }
            """),
            Example("""
            static func foo() -> Int {
                ↓0
            }
            """),
            Example("""
            func foo() -> (Int, String) {
                ↓(0, "bar")
            }
            """),
        ]

        static let corrections = [
            Example("""
            func foo() -> Int {
                0
            }
            """): Example("""
                func foo() -> Int {
                    return 0
                }
                """),
            Example("""
            class Foo {
                func foo() -> Int {
                    0
                }
            }
            """): Example("""
                class Foo {
                    func foo() -> Int {
                        return 0
                    }
                }
                """),
            Example("""
            static func foo() -> Int {
                0
            }
            """): Example("""
                static func foo() -> Int {
                    return 0
                }
                """),
            Example("""
            func foo() -> (Int, String) {
                (0, "bar")
            }
            """): Example("""
                func foo() -> (Int, String) {
                    return (0, "bar")
                }
                """),
        ]
    }

    struct GetterExamples {
        static let nonTriggeringExamples = [
            Example("var foo: Bool { return true }"),
            Example("""
            class Foo {
                var bar: Int {
                    get {
                        return 0
                    }
                }
            }
            """),
            Example("""
            class Foo {
                static var bar: Int {
                    return 0
                }
            }
            """),
            Example("""
            var foo: Bool {
                bar()
                return true
            }
            """),
        ]

        static let triggeringExamples = [
            Example("var foo: Bool { ↓true }"),
            Example("""
            class Foo {
                var bar: Int {
                    get {
                        ↓0
                    }
                }
            }
            """),
            Example("""
            class Foo {
                static var bar: Int {
                    ↓0
                }
            }
            """),
        ]

        static let corrections = [
            Example("var foo: Bool { true }"): Example("var foo: Bool { return true }"),
            Example("""
            class Foo {
                var bar: Int {
                    get {
                        0
                    }
                }
            }
            """): Example("""
                class Foo {
                    var bar: Int {
                        get {
                            return 0
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
            """): Example("""
                class Foo {
                    static var bar: Int {
                        return 0
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
            Example("""
            class C {
                init?() {
                    return nil
                }
            }
            """),
            Example("""
            class C {
                init() {}
            }
            """),
            Example("""
            class C {
                init() {
                    setup()
                }
            }
            """),
        ]

        static let triggeringExamples = [
            Example("""
            class C {
                init?() {
                    ↓nil
                }
            }
            """),
        ]

        static let corrections = [
            Example("""
            class C {
                init?() {
                    nil
                }
            }
            """): Example("""
                class C {
                    init?() {
                        return nil
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
            Example("""
            class C {
                subscript(i: Int) -> Int {
                    return i
                }
            }
            """),
        ]

        static let triggeringExamples = [
            Example("""
            class C {
                subscript(i: Int) -> Int {
                    ↓i
                }
            }
            """),
        ]

        static let corrections = [
            Example("""
            class C {
                subscript(i: Int) -> Int {
                    i
                }
            }
            """): Example("""
                class C {
                    subscript(i: Int) -> Int {
                        return i
                    }
                }
                """),
        ]
    }

    struct MixedExamples {
        static let corrections: [Example: Example] = [
            Example("""
                func foo() -> Int {
                    ↓[1, 2].first(where: {
                        ↓true
                    })!
                }
                """, configuration: closureConfig): Example("""
                func foo() -> Int {
                    return [1, 2].first(where: {
                        return true
                    })!
                }
                """),
            Example("""
                func foo() -> Int {
                    ↓[1, 2].first(where: {
                        true
                    })!
                }
                """): Example("""
                func foo() -> Int {
                    return [1, 2].first(where: {
                        true
                    })!
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
                preconditionFailure("Duplicate correction in explicit return rule examples.")
            }
        }
    }
}
