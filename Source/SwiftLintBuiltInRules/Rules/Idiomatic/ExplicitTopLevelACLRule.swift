import SwiftSyntax

@SwiftSyntaxRule
struct ExplicitTopLevelACLRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "explicit_top_level_acl",
        name: "Explicit Top Level ACL",
        description: "Top-level declarations should specify Access Control Level keywords explicitly",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("internal enum A {}"),
            Example("public final class B {}"),
            Example("private struct C {}"),
            Example("internal enum A { enum B {} }"),
            Example("internal final class Foo {}"),
            Example("internal\nclass Foo {}"),
            Example("internal func a() {}"),
            Example("extension A: Equatable {}"),
            Example("extension A {}")
        ],
        triggeringExamples: [
            Example("↓enum A {}"),
            Example("final ↓class B {}"),
            Example("↓struct C {}"),
            Example("↓func a() {}"),
            Example("internal let a = 0\n↓func b() {}")
        ]
    )
}

private extension ExplicitTopLevelACLRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ClassDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.structKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.enumKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.protocolKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.actorKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.typealiasKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        private func hasViolation(modifiers: DeclModifierListSyntax?) -> Bool {
            guard let modifiers else {
                return true
            }
            return !modifiers.contains { $0.asAccessLevelModifier != nil && $0.detail == nil }
        }
    }
}
