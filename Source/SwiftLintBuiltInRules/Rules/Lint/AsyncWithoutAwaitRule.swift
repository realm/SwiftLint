import SwiftLintCore
import SwiftSyntax

// swiftlint:disable file_length

@SwiftSyntaxRule
struct AsyncWithoutAwaitRule: SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "async_without_await",
        name: "Async Without Await",
        description: "Declaration should not be async if it doesn't use await",
        kind: .lint,
        nonTriggeringExamples: [
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
        ],
        triggeringExamples: [
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
        ],
        corrections: [
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
    )
}
private extension AsyncWithoutAwaitRule {
    private struct FuncInfo {
        var containsAwait = false
        let asyncToken: TokenSyntax?

        init(asyncToken: TokenSyntax?) {
            self.asyncToken = asyncToken
        }
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var functionScopes = Stack<FuncInfo>()
        private var pendingAsync: TokenSyntax?

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.body != nil else {
                return .visitChildren
            }

            let asyncToken = node.signature.effectSpecifiers?.asyncSpecifier
            functionScopes.push(.init(asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.body != nil {
                checkViolation()
            }
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            functionScopes.push(.init(asyncToken: pendingAsync))
            pendingAsync = nil

            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
            checkViolation()
        }

        override func visitPost(_: AwaitExprSyntax) {
            functionScopes.modifyLast {
                $0.containsAwait = true
            }
        }

        override func visitPost(_ node: TypeEffectSpecifiersSyntax) {
            if let asyncNode = node.asyncSpecifier {
                pendingAsync = asyncNode
            }
        }

        override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.body != nil else {
                return .visitChildren
            }

            let asyncToken = node.effectSpecifiers?.asyncSpecifier
            functionScopes.push(.init(asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_ node: AccessorDeclSyntax) {
            if node.body != nil {
                checkViolation()
            }
        }

        override func visitPost(_: PatternBindingSyntax) {
            pendingAsync = nil
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.body != nil else {
                return .visitChildren
            }

            let asyncToken = node.signature.effectSpecifiers?.asyncSpecifier
            functionScopes.push(.init(asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if node.body != nil {
                checkViolation()
            }
        }

        override func visitPost(_: TypeAliasDeclSyntax) {
            pendingAsync = nil
        }

        private func checkViolation() {
            guard let info = functionScopes.pop(),
                    let asyncToken = info.asyncToken,
                    !info.containsAwait
            else {
                return
            }

            violations.append(
                at: asyncToken.positionAfterSkippingLeadingTrivia,
                correction: .init(
                    start: asyncToken.positionAfterSkippingLeadingTrivia,
                    end: asyncToken.endPosition,
                    replacement: ""
                )
            )
        }
    }
}
