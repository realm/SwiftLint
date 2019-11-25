internal struct ImplicitReturnRuleExamples {
    internal struct GenericExamples {
        static let nonTriggeringExamples = ["if foo {\n  return 0\n}"]
    }

    internal struct ClosureExamples {
        static let nonTriggeringExamples = [
            "foo.map { $0 + 1 }",
            "foo.map({ $0 + 1 })",
            "foo.map { value in value + 1 }",
            """
            [1, 2].first(where: {
                true
            })
            """
        ]

        static let triggeringExamples = [
            """
            foo.map { value in
                return value + 1
            }
            """,
            """
            foo.map {
                return $0 + 1
            }
            """,
            "foo.map({ return $0 + 1})",
            """
            [1, 2].first(where: {
                return true
            })
            """
        ]

        static let corrections = [
            "foo.map { value in\n  return value + 1\n}": "foo.map { value in\n  value + 1\n}",
            "foo.map {\n  return $0 + 1\n}": "foo.map {\n  $0 + 1\n}",
            "foo.map({ return $0 + 1})": "foo.map({ $0 + 1})",
            "[1, 2].first(where: {\n  return true })": "[1, 2].first(where: {\n  true })"
        ]
    }

    internal struct FunctionExamples {
        static let nonTriggeringExamples = [
            """
            func foo() -> Int {
                0
            }
            """,
            """
            class Foo {
                func foo() -> Int { 0 }
            }
            """
        ]

        static let triggeringExamples = [
            """
            func foo() -> Int {
                return 0
            }
            """,
            """
            class Foo {
                func foo() -> Int { return 0 }
            }
            """
        ]

        static let corrections = [
            "func foo() -> Int {\n  return 0\n}": "func foo() -> Int {\n  0\n}",
            // swiftlint:disable:next line_length
            "class Foo {\n  func foo() -> Int {\n    return 0\n  }\n}": "class Foo {\n  func foo() -> Int {\n    0\n  }\n}"
        ]
    }

    internal struct GetterExamples {
        static let nonTriggeringExamples = [
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
            """
        ]

        static let triggeringExamples = [
            "var foo: Bool { return true }",
            """
            class Foo {
                var bar: Int {
                    get {
                        return 0
                    }
                }
            }
            """,
            """
            class Foo {
                static var bar: Int {
                    return 0
                }
            }
            """
        ]

        static let corrections = [
            "var foo: Bool { return true }": "var foo: Bool { true }",
            // swiftlint:disable:next line_length
            "class Foo {\n  var bar: Int {\n    get {\n      return 0\n    }\n  }\n}": "class Foo {\n  var bar: Int {\n    get {\n      0\n    }\n  }\n}"
        ]
    }

    static let nonTriggeringExamples = GenericExamples.nonTriggeringExamples +
        ClosureExamples.nonTriggeringExamples +
        FunctionExamples.nonTriggeringExamples +
        GetterExamples.nonTriggeringExamples

    static let triggeringExamples = ClosureExamples.triggeringExamples +
        FunctionExamples.triggeringExamples +
        GetterExamples.triggeringExamples

    static var corrections: [String: String] {
        let corrections: [[String: String]] = [
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
