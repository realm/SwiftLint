internal struct AsyncWithoutAwaitRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        func test() {
            func test() async {
                await test()
            }
        },
        """),
        Example("""
        func test() {
            func test() async {
                await test().value
            }
        },
        """),
        Example("""
        func test() async {
            await scheduler.task { foo { bar() } }
        }
        """),
        Example("""
        func test() async {
            perform(await try foo().value)
        }
        """),
        Example("""
        func test() async {
            perform(try await foo())
        }
        """),
        Example("""
        func test() async {
            await perform()
            func baz() {
                qux()
            }
        }
        """),
        Example("""
        let x: () async -> Void = {
            await test()
        }
        """),
        Example("""
        let x: () async -> Void = {
            await { await test() }()
        }
        """),
        Example("""
        func test() async {
            await foo()
        }
        let x = { bar() }
        """),
        Example("""
        let x: (() async -> Void)? = {
            await { await test() }()
        }
        """),
        Example("""
        let x: (() async -> Void)? = nil
        let x: () -> Void = { test() }
        """),
        Example("""
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
        """),
        Example("""
        init() async {
            await foo()
        }
        """),
        Example("""
        init() async {
            func test() async {
                await foo()
            }
            await { await foo() }()
        }
        """),
        Example("""
        subscript(row: Int) -> Double {
            get async {
                await foo()
            }
        }
        """),
        Example("""
        func foo() async -> Int
        func bar() async -> Int
        """),
        Example("""
        var foo: Int { get async }
        var bar: Int { get async }
        """),
        Example("""
        init(foo: bar) async
        init(baz: qux) async
        let baz = { qux() }
        """),
        Example("""
        typealias Foo = () async -> Void
        typealias Bar = () async -> Void
        let baz = { qux() }
        """),
        Example("""
        func test() async {
            for await foo in bar {}
        }
        """),
        Example("""
        func test() async {
            while let foo = await bar() {}
        }
        """),
        Example("""
        func test() async {
            async let foo = bar()
            let baz = await foo
        }
        """),
        Example("""
        func test() async {
            async let foo = bar()
            await foo
        }
        """),
        Example("""
        func test() async {
            async let foo = bar()
        }
        """),
        Example("func foo(bar: () async -> Void) { { } }"),
        Example("func foo(bar: () async -> Void = { await baz() }) { {} }"),
        Example("func foo() -> (() async -> Void)? { {} }"),
        Example("""
        func foo(
            bar: () async -> Void,
            baz: () -> Void = {}
        ) { { } }
        """),
        Example("func foo(bar: () async -> Void = {}) { }"),
    ]

    static let triggeringExamples = [
        Example("""
        func test() ↓async {
            perform()
        }
        """),
        Example("""
        func test() {
            func baz() ↓async {
                qux()
            }
            perform()
            func baz() {
                qux()
            }
        }
        """),
        Example("""
        func test() ↓async {
            func baz() async {
                await qux()
            }
        }
        """),
        Example("""
        func test() ↓async {
          func foo() ↓async {}
          let bar = { await foo() }
        }
        """),
        Example("""
        func test() ↓async {
            let bar = {
                func foo() ↓async {}
            }
        }
        """),
        Example("let x: (() ↓async -> Void)? = { test() }"),
        Example("""
        var test: Int {
            get ↓async throws {
                foo()
            }
        }
        """),
        Example("""
        var test: Int {
            get ↓async throws {
                func foo() ↓async {}
                let bar = { await foo() }
            }
        }
        """),
        Example("""
        var test: Int {
            get throws {
                func foo() {}
                let bar: () ↓async -> Void = { foo() }
            }
        }
        """),
        Example("init() ↓async {}"),
        Example("""
        init() ↓async {
            func foo() ↓async {}
            let bar: () ↓async -> Void = { foo() }
        }
        """),
        Example("""
        subscript(row: Int) -> Double {
            get ↓async {
                1.0
            }
        }
        """),
        Example("""
        func test() ↓async {
            for foo in bar {}
        }
        """),
        Example("""
        func test() ↓async {
            while let foo = bar() {}
        }
        """),
    ]

    static let corrections = [
        Example("func test() ↓async {}"): Example("func test() {}"),
        Example("func test() ↓async throws {}"): Example("func test() throws {}"),
        Example("""
        func test() {
            func baz() ↓async {
                qux()
            }
            perform()
            func baz() {
                qux()
            }
        }
        """):
            Example("""
            func test() {
                func baz() {
                    qux()
                }
                perform()
                func baz() {
                    qux()
                }
            }
            """),
        Example("""
        func test() ↓async{
            func baz() async {
                await qux()
            }
        }
        """):
            Example("""
            func test() {
                func baz() async {
                    await qux()
                }
            }
            """),
        Example("""
        func test() ↓async {
          func foo() ↓async {}
          let bar = { await foo() }
        }
        """):
            Example("""
            func test() {
              func foo() {}
              let bar = { await foo() }
            }
            """),
        Example("let x: () ↓async -> Void = { test() }"):
            Example("let x: () -> Void = { test() }"),
        Example("""
        var test: Int {
            get ↓async throws {
                func foo() ↓async {}
                let bar = { await foo() }
            }
        }
        """):
            Example("""
            var test: Int {
                get throws {
                    func foo() {}
                    let bar = { await foo() }
                }
            }
            """),
        Example("init() ↓async {}"): Example("init() {}"),
        Example("""
        init() ↓async {
            func foo() ↓async {}
            let bar: () ↓async -> Void = { foo() }
        }
        """):
            Example("""
            init() {
                func foo() {}
                let bar: () -> Void = { foo() }
            }
            """),
        Example("""
        subscript(row: Int) -> Double {
            get ↓async {
                foo()
            }
        }
        """):
            Example("""
            subscript(row: Int) -> Double {
                get {
                    foo()
                }
            }
            """),
    ]
}
