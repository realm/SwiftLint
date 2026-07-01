import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ExplicitTopLevelACLRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "explicit_top_level_acl",
        name: "Explicit Top Level ACL",
        description: "Top-level declarations should specify Access Control Level keywords explicitly",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "internal enum A {}",
            "public final class B {}",
            """
            private struct S1 {
                struct S2 {}
            }
            """,
            "internal enum A { enum B {} }",
            "internal final actor Foo {}",
            "internal typealias Foo = Bar",
            "internal func a() {}",
            "extension A: Equatable {}",
            "extension A {}",
            "f { func f() {} }".excludeFromDocumentation(),
            "do { func f() {} }".excludeFromDocumentation(),
        ]),
        triggeringExamples: #examples([
            "↓enum A {}",
            "final ↓class B {}",
            "↓protocol P {}",
            "↓func a() {}",
            "internal let a = 0\n↓func b() {}",
        ])
    )
}

private extension ExplicitTopLevelACLRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ClassDeclSyntax) {
            collectViolations(decl: node, token: node.classKeyword)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            collectViolations(decl: node, token: node.structKeyword)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            collectViolations(decl: node, token: node.enumKeyword)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            collectViolations(decl: node, token: node.protocolKeyword)
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            collectViolations(decl: node, token: node.actorKeyword)
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            collectViolations(decl: node, token: node.typealiasKeyword)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            collectViolations(decl: node, token: node.funcKeyword)
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            collectViolations(decl: node, token: node.bindingSpecifier)
        }

        override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        private func collectViolations(decl: some WithModifiersSyntax, token: TokenSyntax) {
            if decl.modifiers.accessLevelModifier == nil {
                violations.append(token.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
