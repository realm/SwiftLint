import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct VoidReturnRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "void_return",
        name: "Void Return",
        description: "Prefer `-> Void` over `-> ()`",
        kind: .style,
        nonTriggeringExamples: [
            Example("let abc: () -> Void = {}"),
            Example("let abc: () -> (VoidVoid) = {}"),
            Example("func foo(completion: () -> Void)"),
            Example("let foo: (ConfigurationTests) -> () throws -> Void"),
            Example("let foo: (ConfigurationTests) ->   () throws -> Void"),
            Example("let foo: (ConfigurationTests) ->() throws -> Void"),
            Example("let foo: (ConfigurationTests) -> () -> Void"),
            Example("let foo: () -> () async -> Void"),
            Example("let foo: () -> () async throws -> Void"),
            Example("let foo: () -> () async -> Void"),
            Example("func foo() -> () async throws -> Void {}"),
            Example("func foo() async throws -> () async -> Void { return {} }"),
            Example("func foo() -> () async -> Int { 1 }"),
        ],
        triggeringExamples: [
            Example("let abc: () -> ↓() = {}"),
            Example("let abc: () -> ↓(Void) = {}"),
            Example("let abc: () -> ↓(   Void ) = {}"),
            Example("func foo(completion: () -> ↓())"),
            Example("func foo(completion: () -> ↓(   ))"),
            Example("func foo(completion: () -> ↓(Void))"),
            Example("let foo: (ConfigurationTests) -> () throws -> ↓()"),
            Example("func foo() async -> ↓()"),
            Example("func foo() async throws -> ↓()"),
        ],
        corrections: [
            Example("let abc: () -> ↓() = {}"): Example("let abc: () -> Void = {}"),
            Example("let abc: () -> ↓(Void) = {}"): Example("let abc: () -> Void = {}"),
            Example("let abc: () -> ↓(   Void ) = {}"): Example("let abc: () -> Void = {}"),
            Example("func foo(completion: () -> ↓())"): Example("func foo(completion: () -> Void)"),
            Example("func foo(completion: () -> ↓(   ))"): Example("func foo(completion: () -> Void)"),
            Example("func foo(completion: () -> ↓(Void))"): Example("func foo(completion: () -> Void)"),
            Example("let foo: (ConfigurationTests) -> () throws -> ↓()"):
                Example("let foo: (ConfigurationTests) -> () throws -> Void"),
            Example("func foo() async throws -> ↓()"): Example("func foo() async throws -> Void"),
        ]
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
                correctionPositions.append(node.type.positionAfterSkippingLeadingTrivia)
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
