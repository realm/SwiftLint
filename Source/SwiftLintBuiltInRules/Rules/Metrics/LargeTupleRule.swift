import SwiftSyntax

@SwiftSyntaxRule
struct LargeTupleRule: Rule {
    var configuration = LargeTupleConfiguration()

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
            Example(
                "func foo() -> Regex<(Substring, foo: Substring, bar: Substring)>.Match? { nil }",
                configuration: ["ignore_regex": true]
            ),
            Example(
                "let regex: Regex<(Substring, Substring, Substring, Substring)>? = nil",
                configuration: ["ignore_regex": true]
            ),
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
            Example(
                "func foo() async throws -> ↓(Int, Int, Int) {}",
                configuration: ["ignore_regex": false]
            ),
            Example("func foo() async throws -> ↓(Int, ↓(String, String, String), Int) {}"),
            Example("func getDictionaryAndInt() async -> (Dictionary<Int, ↓(String, String, String)>, Int)?"),
        ]
    )
}

private extension LargeTupleRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TupleTypeSyntax) {
            if configuration.ignoreRegex, node.isInsideRegexType {
                return
            }

            let memberCount = node.elements.count
            for parameter in configuration.severityConfiguration.params where memberCount > parameter.value {
                violations.append(.init(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Tuples should have at most \(configuration.severityConfiguration.warning) members",
                    severity: parameter.severity
                ))
                return
            }
        }
    }
}

private extension TupleTypeSyntax {
    /// Check if this tuple is a direct generic argument of a `Regex` type.
    /// Expected chain: TupleType -> GenericArgument -> GenericArgumentList ->
    ///   GenericArgumentClause -> IdentifierType "Regex"
    /// Optionally with OptionalType wrapper: TupleType -> OptionalType -> GenericArgument -> ...
    var isInsideRegexType: Bool {
        var current: Syntax? = Syntax(self)

        // Skip OptionalType wrapper if present (for Regex<(A, B)?>)
        if current?.parent?.is(OptionalTypeSyntax.self) == true {
            current = current?.parent
        }

        guard let genericArgument = current?.parent?.as(GenericArgumentSyntax.self),
              let genericArgumentList = genericArgument.parent?.as(GenericArgumentListSyntax.self),
              let genericArgumentClause = genericArgumentList.parent?.as(GenericArgumentClauseSyntax.self),
              let identifierType = genericArgumentClause.parent?.as(IdentifierTypeSyntax.self),
              identifierType.name.text == "Regex" else {
            return false
        }
        return true
    }
}
