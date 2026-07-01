internal struct AsyncWithoutAwaitRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
        actor A {
            init() async {
                foo()
            }
            func foo() {}
        }
        """,
        """
        func test() {
            func test() async {
                await test()
            }
        },
        """,
        """
        func test() {
            func test() async {
                await test().value
            }
        },
        """,
        """
        func test() async {
            await scheduler.task { foo { bar() } }
        }
        """,
        """
        func test() async {
            perform(await try foo().value)
        }
        """,
        """
        func test() async {
            perform(try await foo())
        }
        """,
        """
        func test() async {
            await perform()
            func baz() {
                qux()
            }
        }
        """,
        """
        let x: () async -> Void = {
            await test()
        }
        """,
        """
        let x: () async -> Void = {
            await { await test() }()
        }
        """,
        """
        func test() async {
            await foo()
        }
        let x = { bar() }
        """,
        """
        let x: (() async -> Void)? = {
            await { await test() }()
        }
        """,
        """
        let x: () -> Void = { test() }
        """,
        """
        var test: Int {
            get async throws {
                try await foo()
            }
        }
        var foo: Int {
            get throws {
                try bar()
            }
        }
        """,
        """
        init() async {
            await foo()
        }
        """,
        """
        init() async {
            func test() async {
                await foo()
            }
            await { await foo() }()
        }
        """,
        """
        subscript(row: Int) -> Double {
            get async {
                await foo()
            }
        }
        """,
        """
        func foo() async -> Int
        func bar() async -> Int
        """,
        """
        var foo: Int { get async }
        var bar: Int { get async }
        """,
        """
        init(foo: bar) async
        init(baz: qux) async
        let baz = { qux() }
        """,
        """
        typealias Foo = () async -> Void
        typealias Bar = () async -> Void
        let baz = { qux() }
        """,
        """
        func test() async {
            for await foo in bar {}
        }
        """,
        """
        func test() async {
            while let foo = await bar() {}
        }
        """,
        """
        func test() async {
            async let foo = bar()
            let baz = await foo
        }
        """,
        """
        func test() async {
            async let foo = bar()
            await foo
        }
        """,
        """
        func test() async {
            async let foo = bar()
        }
        """,
        "func foo(bar: () async -> Void) { { } }",
        "func foo(bar: () async -> Void = { await baz() }) { {} }",
        "func foo() -> (() async -> Void)? { {} }",
        """
        func foo(
            bar: () async -> Void,
            baz: () -> Void = {}
        ) { { } }
        """,
        "func foo(bar: () async -> Void = {}) {}",
        "var foo: (() async -> Void)? = nil",
        "var foo: ((Int) async throws -> Int)? { f }",
        "let foo: ((Int) async throws -> Int)? = { await f($0) }",
        "let foo: () async throws -> ()",
        """
        func f() async throws -> Int {
            try await g {
                let b: Int
                b = 2
            }
        }
        """.excludeFromDocumentation(),
        """
        @concurrent
        func concurrentFunction() async {
            performWork()
        }
        """,
        """
        struct S: Sendable {
            @concurrent
            func alwaysSwitch() async {
                // This is valid - @concurrent functions require async even without await
            }
        }
        """,
        """
        struct ConcurrentInitExample {
            @concurrent
            init() async {
                setup()
            }
            func setup() {}
        }
        """,
        """
        struct ConcurrentClosureExample {
            let c: () async -> Int = { @concurrent in 1 }
        }
        """,
        """
        class Parent {
            func test() async { await foo() }
        }
        class Child: Parent {
            override func test() async { print("Child") }
        }
        """,
        """
        class Parent {
            var prop: Int {
                get async { await fetchValue() }
            }
        }
        class Child: Parent {
            override var prop: Int {
                get async { return 2 }
            }
        }
        """,
        """
        class Base {
            init() async { await setup() }
        }
        class Derived: Base {
            override init() async { print("Derived") }
        }
        """,
    ])

    static let triggeringExamples = #examples([
        """
        func test() ↓async {
            perform()
        }
        """,
        """
        func test() {
            func baz() ↓async {
                qux()
            }
            perform()
            func baz() {
                qux()
            }
        }
        """,
        """
        func test() ↓async {
            func baz() async {
                await qux()
            }
        }
        """,
        """
        func test() ↓async {
          func foo() ↓async {}
          let bar = { await foo() }
        }
        """,
        """
        func test() ↓async {
            let bar = {
                func foo() ↓async {}
            }
        }
        """,
        """
        var test: Int {
            get ↓async throws {
                foo()
            }
        }
        """,
        """
        var test: Int {
            get ↓async throws {
                func foo() ↓async {}
                let bar = { await foo() }
            }
        }
        """,
        "init() ↓async {}",
        """
        init() ↓async {
            func foo() ↓async {}
        }
        """,
        """
        subscript(row: Int) -> Double {
            get ↓async {
                1.0
            }
        }
        """,
        """
        func test() ↓async {
            for foo in bar {}
        }
        """,
        """
        func test() ↓async {
            while let foo = bar() {}
        }
        """,
        "let x: () ↓async -> Void = { }",
        "let x: () ↓async -> Void = { test() }",
        "let x: (() ↓async -> Void)? = nil",
    ])

    static let corrections = #corrections([
        "func test() ↓async {}": "func test() {}",
        "func test() ↓async throws {}": "func test() throws {}",
        """
        func test() {
            func baz() ↓async {
                qux()
            }
            perform()
            func baz() {
                qux()
            }
        }
        """:
            """
            func test() {
                func baz() {
                    qux()
                }
                perform()
                func baz() {
                    qux()
                }
            }
            """,
        """
        func test() ↓async{
            func baz() async {
                await qux()
            }
        }
        """:
            """
            func test() {
                func baz() async {
                    await qux()
                }
            }
            """,
        """
        func test() ↓async {
          func foo() ↓async {}
          let bar = { await foo() }
        }
        """:
            """
            func test() {
              func foo() {}
              let bar = { await foo() }
            }
            """,
        """
        var test: Int {
            get ↓async throws {
                func foo() ↓async {}
                let bar = { await foo() }
            }
        }
        """:
            """
            var test: Int {
                get throws {
                    func foo() {}
                    let bar = { await foo() }
                }
            }
            """,
        "init() ↓async {}": "init() {}",
        """
        subscript(row: Int) -> Double {
            get ↓async {
                foo()
            }
        }
        """:
            """
            subscript(row: Int) -> Double {
                get {
                    foo()
                }
            }
            """,
    ])
}
