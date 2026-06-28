import SwiftLintCore
import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(explicitRewriter: true)
struct VoidReturnRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "void_return",
        name: "Void Return",
        description: "Prefer `-> Void` over `-> ()`",
        kind: .style,
        nonTriggeringExamples: #examples([
            "let abc: () -> Void = {}",
            "let abc: () -> (VoidVoid) = {}",
            "func foo(completion: () -> Void)",
            "let foo: (ConfigurationTests) -> () throws -> Void",
            "let foo: (ConfigurationTests) ->   () throws -> Void",
            "let foo: (ConfigurationTests) ->() throws -> Void",
            "let foo: (ConfigurationTests) -> () -> Void",
            "let foo: () -> () async -> Void",
            "let foo: () -> () async throws -> Void",
            "let foo: () -> () async -> Void",
            "func foo() -> () async throws -> Void {}",
            "func foo() async throws -> () async -> Void { return {} }",
            "func foo() -> () async -> Int { 1 }",
        ]),
        triggeringExamples: #examples([
            "let abc: () -> ↓() = {}",
            "let abc: () -> ↓(Void) = {}",
            "let abc: () -> ↓(   Void ) = {}",
            "func foo(completion: () -> ↓())",
            "func foo(completion: () -> ↓(   ))",
            "func foo(completion: () -> ↓(Void))",
            "let foo: (ConfigurationTests) -> () throws -> ↓()",
            "func foo() async -> ↓()",
            "func foo() async throws -> ↓()",
        ]),
        corrections: #examplesDictionary([
            "let abc: () -> ↓() = {}": "let abc: () -> Void = {}",
            "let abc: () -> ↓(Void) = {}": "let abc: () -> Void = {}",
            "let abc: () -> ↓(   Void ) = {}": "let abc: () -> Void = {}",
            "func foo(completion: () -> ↓())": "func foo(completion: () -> Void)",
            "func foo(completion: () -> ↓(   ))": "func foo(completion: () -> Void)",
            "func foo(completion: () -> ↓(Void))": "func foo(completion: () -> Void)",
            "let foo: (ConfigurationTests) -> () throws -> ↓()":
                "let foo: (ConfigurationTests) -> () throws -> Void",
            "func foo() async throws -> ↓()": "func foo() async throws -> Void",
        ])
    )
}

private extension VoidReturnRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ReturnClauseSyntax) {
            if node.violates {
                violations.append(node.type.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ReturnClauseSyntax) -> ReturnClauseSyntax {
            if node.violates {
                numberOfCorrections += 1
                let node = node
                    .with(\.type, TypeSyntax(IdentifierTypeSyntax(name: "Void")))
                    .with(\.trailingTrivia, node.type.trailingTrivia)
                return super.visit(node)
            }
            return super.visit(node)
        }
    }
}

private extension ReturnClauseSyntax {
    var violates: Bool {
        if let type = type.as(TupleTypeSyntax.self) {
            let elements = type.elements
            return elements.isEmpty || elements.onlyElement?.type.as(IdentifierTypeSyntax.self)?.name.text == "Void"
        }
        return false
    }
}
