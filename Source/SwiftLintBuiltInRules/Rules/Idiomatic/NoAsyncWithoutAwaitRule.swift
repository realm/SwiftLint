import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct NoAsyncWithoutAwaitRule: SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_async_without_await",
        name: "No Async Without Await",
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
        ],
        corrections: [
            Example("func test() ↓async {}"): Example("func test() {}"),
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
            """): Example("""
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
            """): Example("""
            func test() {
                func baz() async {
                    await qux()
                }
            }
            """),
            Example("""
            func f() ↓async {
              func g() ↓async {}
              let x = { await g() }
            }
            """): Example("""
            func f() {
              func g() {}
              let x = { await g() }
            }
            """)
        ]
    )
}
private extension NoAsyncWithoutAwaitRule {
    private struct FuncInfo {
        var containsCount = false
        let isAsync: Bool
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var awaitCount = Stack<FuncInfo>()

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            awaitCount.push(.init(isAsync: node.asyncSpecifier != nil))

            return super.visit(node)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let info = awaitCount.pop(), let asyncSymbol = node.asyncSpecifier else {
                return
            }

            if !info.containsCount {
                violations.append(
                    at: asyncSymbol.positionAfterSkippingLeadingTrivia,
                    correction: .init(
                        start: asyncSymbol.positionAfterSkippingLeadingTrivia,
                        end: node.body?.positionAfterSkippingLeadingTrivia ?? asyncSymbol.endPositionBeforeTrailingTrivia,
                        replacement: ""
                    )
                )
            }
        }

        override func visitPost(_: AwaitExprSyntax) {
            awaitCount.modifyLast {
                $0.containsCount = true
            }
        }
    }
}

private extension FunctionDeclSyntax {
    var asyncSpecifier: TokenSyntax? {
        signature.effectSpecifiers?.asyncSpecifier
    }
}
