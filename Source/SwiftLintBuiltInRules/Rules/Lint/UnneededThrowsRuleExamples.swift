internal struct UnneededThrowsRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
            func foo() throws {
                try bar()
            }
            """),
        Example("""
            func foo() throws {
                throw Example.failure
            }
            """),
        Example("""
            func foo() throws(Example) {
                throw Example.failure
            }
            """),
        Example("""
            func foo(_ bar: () throws -> T) rethrows -> Int {
                try items.map { try bar() }
            }
            """),
        Example("""
            func foo() {
                func bar() throws {
                    try baz()
                }
                try? bar()
            }
            """),
        Example("""
            protocol Foo {
                func bar() throws
            }
            """),
        Example("""
            func foo() throws {
                guard false else {
                    throw Example.failure
                }
            }
            """),
        Example("""
            func foo() throws {
                do { try bar() }
                catch {
                    throw Example.failure
                }
            }
            """),
        Example("""
            func foo() throws {
                do { try bar() }
                catch {
                    try baz()
                }
            }
            """),
        Example("""
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
        """),
        Example("""
            func foo() throws {
                switch bar {
                case 1: break
                default: try bar()
                }
            }
            """),
        Example("""
            var foo: Int {
                get throws {
                    try bar
                }
            }
            """),
        Example("""
        func foo() throws {
            let bar = Bar()

            if bar.boolean {
                throw Example.failure
            }
        }
        """),
        Example("""
        func foo() throws -> Bar? {
            Bar(try baz())
        }
        """),
        Example("""
        typealias Foo = () throws -> Void
        """),
        Example("""
        enum Foo {
            case foo
            case bar(() throws -> Void)
        }
        """),
        Example("""
        func foo() async throws {
            for try await item in items {}
        }
        """),
        Example("""
        let foo: () throws -> Void
        """),
        Example("""
        let foo: @Sendable () throws -> Void
        """),
        Example("""
        let foo: (() throws -> Void)?
        """),
        Example("""
        func foo(_ bar: () throws -> Void = {}) {}
        """),
        Example("""
        func foo() async throws {
            func foo() {}
            for _ in 0..<count {
                foo()
                try await bar()
            }
        }
        """),
        Example("""
        func foo() throws {
            do { try bar() }
            catch Example.failure {}
        }
        """),
        Example("""
        func foo() throws {
            do { try bar() }
            catch is SomeError { throw AnotherError }
            catch is AnotherError {}
        }
        """),
        Example("let s: S<() throws -> Void> = S()"),
        Example("let foo: (() throws -> Void, Int) = ({}, 1)"),
        Example("let foo: (Int, () throws -> Void) = (1, {})"),
        Example("let foo: (Int, Int, () throws -> Void) = (1, 1, {})"),
        Example("let foo: () throws -> Void = { try bar() }"),
        Example("let foo: () throws -> Void = bar"),
    ]

    static let triggeringExamples = [
        Example("func foo() ↓throws {}"),
        Example("let foo: () ↓throws -> Void = {}"),
        Example("let foo: (() ↓throws -> Void) = {}"),
        Example("let foo: (() ↓throws -> Void)? = {}"),
        Example("let foo: @Sendable () ↓throws -> Void = {}"),
        Example("func foo(bar: () throws -> Void) ↓rethrows {}"),
        Example("init() ↓throws {}"),
        Example("""
            func foo() ↓throws {
                bar()
            }
            """),
        Example("""
            func foo() ↓throws(Example) {
                bar()
            }
            """),
        Example("""
            func foo() {
                func bar() ↓throws {}
                bar()
            }
            """),
        Example("""
            func foo() {
                func bar() ↓throws {
                    baz()
                }
                bar()
            }
            """),
        Example("""
            func foo() {
                func bar() ↓throws {
                    baz()
                }
                try? bar()
            }
            """),
        Example("""
            func foo() ↓throws {
                func bar() ↓throws {
                    baz()
                }
            }
            """),
        Example("""
            func foo() ↓throws {
                do { try bar() }
                catch {}
            }
            """),
        Example("""
            func foo() ↓throws {
                do {}
                catch {}
            }
            """),
        Example("""
            func foo() ↓throws(Example) {
                do {}
                catch {}
            }
            """),
        Example("""
            func foo() {
                do {
                    func bar() ↓throws {}
                    try bar()
                } catch {}
            }
            """),
        Example("""
            func foo() ↓throws {
                do {
                    try bar()
                    func baz() throws { try bar() }
                    try baz()
                } catch {}
            }
            """),
        Example("""
            func foo() ↓throws {
                do {
                    try bar()
                } catch {
                    do {
                        throw Example.failure
                    } catch {}
                }
            }
            """),
        Example("""
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
            """),
        Example("""
            func foo() ↓throws {
                switch bar {
                case 1: break
                default: break
                }
            }
            """),
        Example("""
            func foo() ↓throws {
                _ = try? bar()
            }
            """),
        Example("""
            func foo() ↓throws {
                Task {
                    try bar()
                }
            }
            """),
        Example("""
            func foo() throws {
                try bar()
                Task {
                    func baz() ↓throws {}
                }
            }
            """),
        Example("""
            var foo: Int {
                get ↓throws {
                    0
                }
            }
            """),
        Example("""
        func foo() ↓throws {
            do { try bar() }
            catch Example.failure {}
            catch is SomeError {}
            catch {}
        }
        """),
        Example("""
        func foo() throws {
            bar(1) {
                try baz()
            }
        }
        """),
    ]

    static let corrections = [
        Example("func foo() ↓throws {}"): Example("func foo() {}"),
        Example("init() ↓throws {}"): Example("init() {}"),
        Example("""
        func foo() {
            func bar() ↓throws {}
            bar()
        }
        """): Example("""
            func foo() {
                func bar() {}
                bar()
            }
            """),
        Example("""
            var foo: Int {
                get ↓throws {
                    0
                }
            }
            """): Example("""
            var foo: Int {
                get {
                    0
                }
            }
            """),
        Example("""
            var foo: Int {
                get ↓throws(Example) {
                    0
                }
            }
            """): Example("""
            var foo: Int {
                get {
                    0
                }
            }
            """),
        Example("""
            let foo: () ↓throws -> Void = {}
            """): Example("""
            let foo: () -> Void = {}
            """),
        Example("""
            let foo: () ↓throws(Example) -> Void = {}
            """): Example("""
            let foo: () -> Void = {}
            """),
        Example("""
            func foo() ↓throws {
                do {}
                catch {}
            }
            """): Example("""
            func foo() {
                do {}
                catch {}
            }
            """),
        Example("""
            func foo() ↓throws(Example) {
                do {}
                catch {}
            }
            """): Example("""
            func foo() {
                do {}
                catch {}
            }
            """),
        Example("func f() ↓throws /* comment */ {}"): Example("func f() /* comment */ {}"),
        Example("func f() /* comment */ ↓throws /* comment */ {}"): Example("func f() /* comment */ /* comment */ {}"),
    ]
}
