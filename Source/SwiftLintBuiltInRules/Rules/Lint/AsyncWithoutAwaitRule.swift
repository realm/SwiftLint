import SwiftLintCore
import SwiftSyntax

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
        ]
    )
}
private extension AsyncWithoutAwaitRule {
    private struct FuncInfo {
        var containsAwait = false
        let isAsync: Bool
        let asyncToken: TokenSyntax?

        init(containsAwait: Bool = false, isAsync: Bool, asyncToken: TokenSyntax? = nil) {
            self.containsAwait = containsAwait
            self.isAsync = isAsync
            self.asyncToken = asyncToken
        }
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var awaitCount = Stack<FuncInfo>()

        private var pendingAsync: TokenSyntax?

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            awaitCount.push(.init(isAsync: node.asyncSpecifier != nil, asyncToken: node.asyncSpecifier))

            return super.visit(node)
        }

        override func visitPost(_: FunctionDeclSyntax) {
            collect()
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            awaitCount.push(.init(isAsync: pendingAsync != nil, asyncToken: pendingAsync))
            pendingAsync = nil

            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
            collect()
        }

        override func visitPost(_: AwaitExprSyntax) {
            awaitCount.modifyLast {
                $0.containsAwait = true
            }
        }

        override func visitPost(_ node: TypeEffectSpecifiersSyntax) {
            if let asyncNode = node.asyncSpecifier {
                pendingAsync = asyncNode
            }
        }

        override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
            let asyncToken = node.effectSpecifiers?.asyncSpecifier
            awaitCount.push(.init(isAsync: asyncToken != nil, asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_: AccessorDeclSyntax) {
            collect()
        }

        override func visitPost(_: PatternBindingSyntax) {
            pendingAsync = nil
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            let asyncToken = node.signature.effectSpecifiers?.asyncSpecifier
            awaitCount.push(.init(isAsync: asyncToken != nil, asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_: InitializerDeclSyntax) {
            collect()
        }

        private func collect() {
            guard let info = awaitCount.pop(), info.isAsync else {
                return
            }

            if !info.containsAwait, let asyncToken = info.asyncToken {
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
}

private extension FunctionDeclSyntax {
    var asyncSpecifier: TokenSyntax? {
        signature.effectSpecifiers?.asyncSpecifier
    }
}
