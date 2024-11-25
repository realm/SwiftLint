import SwiftSyntax

@SwiftSyntaxRule
struct NoAsyncWithoutAwaitRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_async_without_await",
        name: "No sync without await",
        description: "Function should not be async if doesn't use await",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            func test() {
                func test() async {
                    await test()
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
                perform(await try foo())
            }
            """),
            Example("""
            func test() async {
                perform(try await foo())
            }
            """
            ),
            Example(
            """
            func test() async {
                await perform()
                func baz() {
                    quz()
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            func testFailed() ↓async {
                perform()
            }
            """),
            Example(
            """
            func test() {
                func baz() ↓async{
                    quz()
                }
                perform()
                func baz() {
                    quz()
                }
            }
            """)
        ]
    )
}
private extension NoAsyncWithoutAwaitRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private struct FuncInfo {
            var awaitCount: Int = 0
            let isAsync: Bool
        }

        private var awaitCount = Stack<FuncInfo>()

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            awaitCount.push(.init(isAsync: node.asyncSpecifier != nil))

            return super.visit(node)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let info = awaitCount.pop(), let asyncSymbol = node.asyncSpecifier else {
                return
            }

            if info.awaitCount == 0 {
                violations.append(asyncSymbol.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.parent?.kind == .awaitExpr || node.parent?.kind == .tryExpr && node.parent?.parent?.kind == .awaitExpr {
                awaitCount.modifyLast {
                    $0.awaitCount += 1
                }
            }
        }
    }
}

private extension FunctionDeclSyntax {
    var asyncSpecifier: TokenSyntax? {
        guard let asyncSpecifier = signature.effectSpecifiers?.asyncSpecifier else {
            return nil
        }

        return asyncSpecifier
    }
}
