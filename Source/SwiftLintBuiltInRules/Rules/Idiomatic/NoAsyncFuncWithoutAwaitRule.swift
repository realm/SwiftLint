import SwiftSyntax

@SwiftSyntaxRule
struct NoAsyncFuncWithoutAwaitRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_async_func_without_await",
        name: "No sync func without await",
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
            """
            )
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
