import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ExplicitTopLevelACLRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "explicit_top_level_acl",
        name: "Explicit Top Level ACL",
        description: "Top-level declarations should specify Access Control Level keywords explicitly",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("internal enum A {}"),
            Example("public final class B {}"),
            Example("""
                private struct S1 {
                    struct S2 {}
                }
                """),
            Example("internal enum A { enum B {} }"),
            Example("internal final actor Foo {}"),
            Example("internal typealias Foo = Bar"),
            Example("internal func a() {}"),
            Example("extension A: Equatable {}"),
            Example("extension A {}"),
            Example("f { func f() {} }", excludeFromDocumentation: true),
            Example("do { func f() {} }", excludeFromDocumentation: true),
        ],
        triggeringExamples: [
            Example("↓enum A {}"),
            Example("final ↓class B {}"),
            Example("↓protocol P {}"),
            Example("↓func a() {}"),
            Example("internal let a = 0\n↓func b() {}"),
        ]
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
