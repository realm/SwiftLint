import SwiftSyntax

@SwiftSyntaxRule
struct LargeTupleRule: Rule {
    var configuration = LargeTupleConfiguration()

    static let description = RuleDescription(
        identifier: "large_tuple",
        name: "Large Tuple",
        description: "Tuples shouldn't have too many members. Create a custom type instead.",
        kind: .metrics,
        nonTriggeringExamples: #examples([
            "let foo: (Int, Int)",
            "let foo: (start: Int, end: Int)",
            "let foo: (Int, (Int, String))",
            "func foo() -> (Int, Int)",
            "func foo() -> (Int, Int) {}",
            "func foo(bar: String) -> (Int, Int)",
            "func foo(bar: String) -> (Int, Int) {}",
            "func foo() throws -> (Int, Int)",
            "func foo() throws -> (Int, Int) {}",
            "let foo: (Int, Int, Int) -> Void",
            "let foo: (Int, Int, Int) throws -> Void",
            "func foo(bar: (Int, String, Float) -> Void)",
            "func foo(bar: (Int, String, Float) throws -> Void)",
            "var completionHandler: ((_ data: Data?, _ resp: URLResponse?, _ e: NSError?) -> Void)!",
            "func getDictionaryAndInt() -> (Dictionary<Int, String>, Int)?",
            "func getGenericTypeAndInt() -> (Type<Int, String, Float>, Int)?",
            "func foo() async -> (Int, Int)",
            "func foo() async -> (Int, Int) {}",
            "func foo(bar: String) async -> (Int, Int)",
            "func foo(bar: String) async -> (Int, Int) {}",
            "func foo() async throws -> (Int, Int)",
            "func foo() async throws -> (Int, Int) {}",
            "let foo: (Int, Int, Int) async -> Void",
            "let foo: (Int, Int, Int) async throws -> Void",
            "func foo(bar: (Int, String, Float) async -> Void)",
            "func foo(bar: (Int, String, Float) async throws -> Void)",
            "func getDictionaryAndInt() async -> (Dictionary<Int, String>, Int)?",
            "func getGenericTypeAndInt() async -> (Type<Int, String, Float>, Int)?",
            "func foo() -> Regex<(Substring, foo: Substring, bar: Substring)>.Match? { nil }"
                .configuration(["ignore_regex": true]),
            "let regex: Regex<(Substring, Substring, Substring, Substring)>? = nil"
                .configuration(["ignore_regex": true]),
            "var regex: Regex<(Substring, Substring, Substring, Substring)?>.Match? { nil }"
                .configuration(["ignore_regex": true]),
        ]),
        triggeringExamples: #examples([
            "let foo: ↓(Int, Int, Int)",
            "let foo: ↓(start: Int, end: Int, value: String)",
            "let foo: (Int, ↓(Int, Int, Int))",
            "func foo(bar: ↓(Int, Int, Int))",
            "func foo() -> ↓(Int, Int, Int)",
            "func foo() -> ↓(Int, Int, Int) {}",
            "func foo(bar: String) -> ↓(Int, Int, Int)",
            "func foo(bar: String) -> ↓(Int, Int, Int) {}",
            "func foo() throws -> ↓(Int, Int, Int)",
            "func foo() throws -> ↓(Int, Int, Int) {}",
            "func foo() throws -> ↓(Int, ↓(String, String, String), Int) {}",
            "func getDictionaryAndInt() -> (Dictionary<Int, ↓(String, String, String)>, Int)?",
            "func foo(bar: ↓(Int, Int, Int)) async",
            "func foo() async -> ↓(Int, Int, Int)",
            "func foo() async -> ↓(Int, Int, Int) {}",
            "func foo(bar: String) async -> ↓(Int, Int, Int)",
            "func foo(bar: String) async -> ↓(Int, Int, Int) {}",
            "func foo() async throws -> ↓(Int, Int, Int)",
            "func foo() async throws -> ↓(Int, Int, Int) {}".configuration(["ignore_regex": false]),
            "func foo() async throws -> ↓(Int, ↓(String, String, String), Int) {}",
            "func getDictionaryAndInt() async -> (Dictionary<Int, ↓(String, String, String)>, Int)?",
        ])
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
