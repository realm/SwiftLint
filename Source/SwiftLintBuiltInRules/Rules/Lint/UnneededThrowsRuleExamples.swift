// swiftlint:disable file_length

struct UnneededThrowsRuleExamples { // swiftlint:disable:this type_body_length
    static let nonTriggeringExamples = #examples([
        """
            func foo() throws {
                try bar()
            }
            """,
        """
            func foo() throws {
                throw Example.failure
            }
            """,
        """
            func foo() throws(Example) {
                throw Example.failure
            }
            """,
        """
            func foo(_ bar: () throws -> T) rethrows -> Int {
                try items.map { try bar() }
            }
            """,
        """
            func foo() {
                func bar() throws {
                    try baz()
                }
                try? bar()
            }
            """,
        """
            protocol Foo {
                func bar() throws
            }
            """,
        """
            func foo() throws {
                guard false else {
                    throw Example.failure
                }
            }
            """,
        """
            func foo() throws {
                do { try bar() }
                catch {
                    throw Example.failure
                }
            }
            """,
        """
            func foo() throws {
                do { try bar() }
                catch {
                    try baz()
                }
            }
            """,
        """
        func foo() throws {
            do {
                throw Example.failure
            } catch {
                do {
                    throw Example.failure
                } catch {
                    throw Example.failure
                }
            }
        }
        """,
        """
            func foo() throws {
                switch bar {
                case 1: break
                default: try bar()
                }
            }
            """,
        """
            var foo: Int {
                get throws {
                    try bar
                }
            }
            """,
        """
        func foo() throws {
            let bar = Bar()

            if bar.boolean {
                throw Example.failure
            }
        }
        """,
        """
        func foo() throws -> Bar? {
            Bar(try baz())
        }
        """,
        """
        typealias Foo = () throws -> Void
        """,
        """
        enum Foo {
            case foo
            case bar(() throws -> Void)
        }
        """,
        """
        func foo() async throws {
            for try await item in items {}
        }
        """,
        """
        let foo: () throws -> Void
        """,
        """
        let foo: @Sendable () throws -> Void
        """,
        """
        let foo: (() throws -> Void)?
        """,
        """
        func foo(_ bar: () throws -> Void = {}) {}
        """,
        """
        func foo() async throws {
            func foo() {}
            for _ in 0..<count {
                foo()
                try await bar()
            }
        }
        """,
        """
        func foo() throws {
            do { try bar() }
            catch Example.failure {}
        }
        """,
        """
        func foo() throws {
            do { try bar() }
            catch is SomeError { throw AnotherError }
            catch is AnotherError {}
        }
        """,
        "let s: S<() throws -> Void> = S()",
        "let foo: (() throws -> Void, Int) = ({}, 1)",
        "let foo: (Int, () throws -> Void) = (1, {})",
        "let foo: (Int, Int, () throws -> Void) = (1, 1, {})",
        "let foo: () throws -> Void = { try bar() }",
        "let foo: () throws -> Void = bar",
        "var foo: () throws -> Void = {}",
        "let x = { () throws -> Void in try baz() }",
        """
        func c() throws {
            b(text: try a()) { print("") }
        }
        """,
        """
        func c() throws {
            b(text: try a())
        }
        """,
        """
        func c() throws {
            [try f()].map { $0 }
        }
        """,
    ])

    static let triggeringExamples = #examples([
        "func foo() ↓throws {}",
        "let foo: () ↓throws -> Void = {}",
        "let foo: (() ↓throws -> Void) = {}",
        "let foo: (() ↓throws -> Void)? = {}",
        "let foo: @Sendable () ↓throws -> Void = {}",
        "func foo(bar: () throws -> Void) ↓rethrows {}",
        "init() ↓throws {}",
        """
            func foo() ↓throws {
                bar()
            }
            """,
        """
            func foo() ↓throws(Example) {
                bar()
            }
            """,
        """
            func foo() {
                func bar() ↓throws {}
                bar()
            }
            """,
        """
            func foo() {
                func bar() ↓throws {
                    baz()
                }
                bar()
            }
            """,
        """
            func foo() {
                func bar() ↓throws {
                    baz()
                }
                try? bar()
            }
            """,
        """
            func foo() ↓throws {
                func bar() ↓throws {
                    baz()
                }
            }
            """,
        """
            func foo() ↓throws {
                do { try bar() }
                catch {}
            }
            """,
        """
            func foo() ↓throws {
                do {}
                catch {}
            }
            """,
        """
            func foo() ↓throws(Example) {
                do {}
                catch {}
            }
            """,
        """
            func foo() {
                do {
                    func bar() ↓throws {}
                    try bar()
                } catch {}
            }
            """,
        """
            func foo() ↓throws {
                do {
                    try bar()
                    func baz() throws { try bar() }
                    try baz()
                } catch {}
            }
            """,
        """
            func foo() ↓throws {
                do {
                    try bar()
                } catch {
                    do {
                        throw Example.failure
                    } catch {}
                }
            }
            """,
        """
            func foo() ↓throws {
                do {
                    try bar()
                } catch {
                    do {
                        try bar()
                        func baz() ↓throws {}
                        try baz()
                    } catch {}
                }
            }
            """,
        """
            func foo() ↓throws {
                switch bar {
                case 1: break
                default: break
                }
            }
            """,
        """
            func foo() ↓throws {
                _ = try? bar()
            }
            """,
        """
            func foo() ↓throws {
                Task {
                    try bar()
                }
            }
            """,
        """
            func foo() throws {
                try bar()
                Task {
                    func baz() ↓throws {}
                }
            }
            """,
        """
            var foo: Int {
                get ↓throws {
                    0
                }
            }
            """,
        """
        func foo() ↓throws {
            do { try bar() }
            catch Example.failure {}
            catch is SomeError {}
            catch {}
        }
        """,
        """
        func foo() ↓throws {
            bar(1) {
                try baz()
            }
        }
        """,
        "let x = { () ↓throws -> Void in baz() }",
        """
        func c() {
            b { (n: String) ↓throws -> String in n }
            d: { try foo() }
        }
        """,
    ])

    static let corrections = #examplesDictionary([
        "func foo() ↓throws {}": "func foo() {}",
        "init() ↓throws {}": "init() {}",
        """
        func foo() {
            func bar() ↓throws {}
            bar()
        }
        """: """
            func foo() {
                func bar() {}
                bar()
            }
            """,
        """
            var foo: Int {
                get ↓throws {
                    0
                }
            }
            """: """
            var foo: Int {
                get {
                    0
                }
            }
            """,
        """
            var foo: Int {
                get ↓throws(Example) {
                    0
                }
            }
            """: """
            var foo: Int {
                get {
                    0
                }
            }
            """,
        """
            let foo: () ↓throws -> Void = {}
            """: """
            let foo: () -> Void = {}
            """,
        """
            let foo: () ↓throws(Example) -> Void = {}
            """: """
            let foo: () -> Void = {}
            """,
        """
            func foo() ↓throws {
                do {}
                catch {}
            }
            """: """
            func foo() {
                do {}
                catch {}
            }
            """,
        """
            func foo() ↓throws(Example) {
                do {}
                catch {}
            }
            """: """
            func foo() {
                do {}
                catch {}
            }
            """,
        "func f() ↓throws /* comment */ {}": "func f() /* comment */ {}",
        "func f() /* comment */ ↓throws /* comment */ {}": "func f() /* comment */ /* comment */ {}",
        "let foo: @Sendable () ↓throws -> Void = {}": "let foo: @Sendable () -> Void = {}",
    ])
}
