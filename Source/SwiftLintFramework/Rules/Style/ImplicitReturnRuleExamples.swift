internal struct ImplicitReturnRuleExamples {
    internal struct GenericExamples {
        static let nonTriggeringExamples = [Example("if foo {\n  return 0\n}")]
    }

    internal struct ClosureExamples {
        static let nonTriggeringExamples = [
            Example("foo.map { $0 + 1 }"),
            Example("foo.map({ $0 + 1 })"),
            Example("foo.map { value in value + 1 }"),
            Example("""
            [1, 2].first(where: {
                true
            })
            """)
        ]

        static let triggeringExamples = [
            Example("""
            foo.map { value in
                return value + 1
            }
            """),
            Example("""
            foo.map {
                return $0 + 1
            }
            """),
            Example("foo.map({ return $0 + 1})"),
            Example("""
            [1, 2].first(where: {
                return true
            })
            """)
        ]

        static let corrections = [
            Example("foo.map { value in\n  return value + 1\n}"): Example("foo.map { value in\n  value + 1\n}"),
            Example("foo.map {\n  return $0 + 1\n}"): Example("foo.map {\n  $0 + 1\n}"),
            Example("foo.map({ return $0 + 1})"): Example("foo.map({ $0 + 1})"),
            Example("[1, 2].first(where: {\n  return true })"): Example("[1, 2].first(where: {\n  true })")
        ]
    }

    internal struct FunctionExamples {
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
            """)
        ]

        static let triggeringExamples = [
            Example("""
            func foo() -> Int {
                return 0
            }
            """),
            Example("""
            class Foo {
                func foo() -> Int { return 0 }
            }
            """)
        ]

        static let corrections = [
            Example("func foo() -> Int {\n  return 0\n}"): Example("func foo() -> Int {\n  0\n}"),
            // swiftlint:disable:next line_length
            Example("class Foo {\n  func foo() -> Int {\n    return 0\n  }\n}"): Example("class Foo {\n  func foo() -> Int {\n    0\n  }\n}")
        ]
    }

    internal struct GetterExamples {
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
            """)
        ]

        static let triggeringExamples = [
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
            """)
        ]

        static let corrections = [
            Example("var foo: Bool { return true }"): Example("var foo: Bool { true }"),
            // swiftlint:disable:next line_length
            Example("class Foo {\n  var bar: Int {\n    get {\n      return 0\n    }\n  }\n}"): Example("class Foo {\n  var bar: Int {\n    get {\n      0\n    }\n  }\n}")
        ]
    }

    static let nonTriggeringExamples = GenericExamples.nonTriggeringExamples +
        ClosureExamples.nonTriggeringExamples +
        FunctionExamples.nonTriggeringExamples +
        GetterExamples.nonTriggeringExamples

    static let triggeringExamples = ClosureExamples.triggeringExamples +
        FunctionExamples.triggeringExamples +
        GetterExamples.triggeringExamples

    static var corrections: [Example: Example] {
        let corrections: [[Example: Example]] = [
            ClosureExamples.corrections,
            FunctionExamples.corrections,
            GetterExamples.corrections
        ]

        return corrections.reduce(into: [:]) { result, element in
            result.merge(element) { _, _ in
                preconditionFailure("Duplicate correction in implicit return rule examples.")
            }
        }
    }
}
