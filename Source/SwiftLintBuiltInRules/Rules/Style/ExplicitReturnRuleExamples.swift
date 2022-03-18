// swiftlint:disable:next type_body_length
internal struct ExplicitReturnRuleExamples {
    internal struct ClosureExamples {
        static let nonTriggeringExamples = [
            Example("""
            foo.map {
                return $0 + 1
            }
            """),
            Example("""
            foo.map({
                return $0 + 1
            })
            """),
            Example("""
            foo.map { value in
                return value + 1
            }
            """),
            Example("""
            [1, 2].first(where: {
                bar($0)
                return true
            })
            """)
        ]

        static let triggeringExamples = [
            Example("""
            foo.map {
                ↓$0 + 1
            }
            """),
            Example("""
            foo.map({
                ↓$0 + 1
            })
            """),
            Example("""
            foo.map { value in
                ↓value + 1
            }
            """)
        ]

        static let corrections = [
            Example("""
            foo.map {
                ↓$0 + 1
            }
            """): Example("""
            foo.map {
                return $0 + 1
            }
            """),
            Example("""
            foo.map({
                ↓$0 + 1
            })
            """): Example("""
            foo.map({
                return $0 + 1
            })
            """),
            Example("""
            foo.map { value in
                ↓value + 1
            }
            """): Example("""
            foo.map { value in
                return value + 1
            }
            """)
        ]
    }

    internal struct FunctionExamples {
        static let nonTriggeringExamples = [
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
            func foo() -> Int {
                if bar {
                    return 1
                } else {
                    return 0
                }
            }
            """),
            Example("""
            func foo() throws {
                throw Foo.bar
            }
            """),
            Example("""
            func foo() -> Int {
                return 0
            }
            """),
            Example("""
            func foo() -> (Int, String) {
                return (0, "bar")
            }
            """),
            Example("""
            func foo() -> Int {
                bar()
                return 0
            }
            """),
            Example("""
            static func foo() -> Int {
                return 0
            }
            """),
            Example("""
            class Foo {
                func foo() -> Int {
                    return 0
                }
            }
            """)
        ]

        static let triggeringExamples = [
            Example("""
            func foo() -> Int {
                ↓0
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
            Example("""
            class Foo {
                func foo() -> Int {
                    ↓0
                }
            }
            """)
        ]

        static let corrections = [
            Example("""
            func foo() -> Int {
                ↓0
            }
            """): Example("""
            func foo() -> Int {
                return 0
            }
            """),
            Example("""
            func foo() -> (Int, String) {
                ↓(0, "foo")
            }
            """): Example("""
            func foo() -> (Int, String) {
                return (0, "foo")
            }
            """),
            Example("""
            static func foo() -> Int {
                ↓0
            }
            """): Example("""
            static func foo() -> Int {
                return 0
            }
            """),
            Example("""
            class Foo {
                func foo() -> Int {
                    ↓0
                }
            }
            """): Example("""
            class Foo {
                func foo() -> Int {
                    return 0
                }
            }
            """)
        ]
    }

    internal struct GetterExamples {
        static let nonTriggeringExamples = [
            Example("""
            var foo: Bool {
                return true
            }
            """),
            Example("""
            var foo: Bool {
                bar()
                return true
            }
            """),
            Example("""
            static var foo: Bool {
                return true
            }
            """),
            Example("""
            var foo: Bool {
                get {
                    return true
                }
            }
            """),
            Example("""
            var foo: Bool {
                set {}

                get {
                    return true
                }
            }
            """),
            Example("""
            class Foo {
                var foo: Bool {
                    return true
                }
            }
            """)
        ]

        static let triggeringExamples = [
            Example("""
            var foo: Bool {
                ↓true
            }
            """),
            Example("""
            static var foo: Bool {
                ↓true
            }
            """),
            Example("""
            var foo: Bool {
                get {
                    ↓true
                }
            }
            """),
            Example("""
            var foo: Bool {
                set {}

                get {
                    ↓true
                }
            }
            """),
            Example("""
            class Foo {
                var foo: Bool {
                    ↓true
                }
            }
            """)
        ]

        static let corrections = [
            Example("""
            var foo: Bool {
                ↓true
            }
            """): Example("""
            var foo: Bool {
                return true
            }
            """),
            Example("""
            static var foo: Bool {
                ↓true
            }
            """): Example("""
            static var foo: Bool {
                return true
            }
            """),
            Example("""
            var foo: Bool {
                get {
                    ↓true
                }
            }
            """): Example("""
            var foo: Bool {
                get {
                    return true
                }
            }
            """),
            Example("""
            var foo: Bool {
                set {}

                get {
                    ↓true
                }
            }
            """): Example("""
            var foo: Bool {
                set {}

                get {
                    return true
                }
            }
            """),
            Example("""
            class Foo {
                var foo: Bool {
                    ↓true
                }
            }
            """): Example("""
            class Foo {
                var foo: Bool {
                    return true
                }
            }
            """)
        ]
    }

    static let nonTriggeringExamples = ClosureExamples.nonTriggeringExamples +
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
            result.merge(element) { _, new in new }
        }
    }
}
