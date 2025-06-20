import SwiftSyntax

@SwiftSyntaxRule
struct LargeTupleRule: Rule {
    var configuration = SeverityLevelsConfiguration<Self>(warning: 2, error: 3)

    static let description = RuleDescription(
        identifier: "large_tuple",
        name: "Large Tuple",
        description: "Tuples shouldn't have too many members. Create a custom type instead.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("let foo: (Int, Int)"),
            Example("let foo: (start: Int, end: Int)"),
            Example("let foo: (Int, (Int, String))"),
            Example("func foo() -> (Int, Int)"),
            Example("func foo() -> (Int, Int) {}"),
            Example("func foo(bar: String) -> (Int, Int)"),
            Example("func foo(bar: String) -> (Int, Int) {}"),
            Example("func foo() throws -> (Int, Int)"),
            Example("func foo() throws -> (Int, Int) {}"),
            Example("let foo: (Int, Int, Int) -> Void"),
            Example("let foo: (Int, Int, Int) throws -> Void"),
            Example("func foo(bar: (Int, String, Float) -> Void)"),
            Example("func foo(bar: (Int, String, Float) throws -> Void)"),
            Example("var completionHandler: ((_ data: Data?, _ resp: URLResponse?, _ e: NSError?) -> Void)!"),
            Example("func getDictionaryAndInt() -> (Dictionary<Int, String>, Int)?"),
            Example("func getGenericTypeAndInt() -> (Type<Int, String, Float>, Int)?"),
            Example("func foo() async -> (Int, Int)"),
            Example("func foo() async -> (Int, Int) {}"),
            Example("func foo(bar: String) async -> (Int, Int)"),
            Example("func foo(bar: String) async -> (Int, Int) {}"),
            Example("func foo() async throws -> (Int, Int)"),
            Example("func foo() async throws -> (Int, Int) {}"),
            Example("let foo: (Int, Int, Int) async -> Void"),
            Example("let foo: (Int, Int, Int) async throws -> Void"),
            Example("func foo(bar: (Int, String, Float) async -> Void)"),
            Example("func foo(bar: (Int, String, Float) async throws -> Void)"),
            Example("func getDictionaryAndInt() async -> (Dictionary<Int, String>, Int)?"),
            Example("func getGenericTypeAndInt() async -> (Type<Int, String, Float>, Int)?"),
        ],
        triggeringExamples: [
            Example("let foo: ↓(Int, Int, Int)"),
            Example("let foo: ↓(start: Int, end: Int, value: String)"),
            Example("let foo: (Int, ↓(Int, Int, Int))"),
            Example("func foo(bar: ↓(Int, Int, Int))"),
            Example("func foo() -> ↓(Int, Int, Int)"),
            Example("func foo() -> ↓(Int, Int, Int) {}"),
            Example("func foo(bar: String) -> ↓(Int, Int, Int)"),
            Example("func foo(bar: String) -> ↓(Int, Int, Int) {}"),
            Example("func foo() throws -> ↓(Int, Int, Int)"),
            Example("func foo() throws -> ↓(Int, Int, Int) {}"),
            Example("func foo() throws -> ↓(Int, ↓(String, String, String), Int) {}"),
            Example("func getDictionaryAndInt() -> (Dictionary<Int, ↓(String, String, String)>, Int)?"),
            Example("func foo(bar: ↓(Int, Int, Int)) async"),
            Example("func foo() async -> ↓(Int, Int, Int)"),
            Example("func foo() async -> ↓(Int, Int, Int) {}"),
            Example("func foo(bar: String) async -> ↓(Int, Int, Int)"),
            Example("func foo(bar: String) async -> ↓(Int, Int, Int) {}"),
            Example("func foo() async throws -> ↓(Int, Int, Int)"),
            Example("func foo() async throws -> ↓(Int, Int, Int) {}"),
            Example("func foo() async throws -> ↓(Int, ↓(String, String, String), Int) {}"),
            Example("func getDictionaryAndInt() async -> (Dictionary<Int, ↓(String, String, String)>, Int)?"),
        ]
    )
}

private extension LargeTupleRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TupleTypeSyntax) {
            let memberCount = node.elements.count
            for parameter in configuration.params where memberCount > parameter.value {
                violations.append(.init(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Tuples should have at most \(configuration.warning) members",
                    severity: parameter.severity
                ))
                return
            }
        }
    }
}
