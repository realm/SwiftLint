import SwiftSyntax

struct ExplicitTopLevelACLRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "explicit_top_level_acl",
        name: "Explicit Top Level ACL",
        description: "Top-level declarations should specify Access Control Level keywords explicitly",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("internal enum A {}\n"),
            Example("public final class B {}\n"),
            Example("private struct C {}\n"),
            Example("internal enum A {\n enum B {}\n}"),
            Example("internal final class Foo {}"),
            Example("internal\nclass Foo {}"),
            Example("internal func a() {}\n"),
            Example("extension A: Equatable {}"),
            Example("extension A {}")
        ],
        triggeringExamples: [
            Example("↓enum A {}\n"),
            Example("final ↓class B {}\n"),
            Example("↓struct C {}\n"),
            Example("↓func a() {}\n"),
            Example("internal let a = 0\n↓func b() {}\n")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ExplicitTopLevelACLRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

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

        override func visitPost(_ node: TypealiasDeclSyntax) {
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
                violations.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        private func hasViolation(modifiers: ModifierListSyntax?) -> Bool {
            guard let modifiers else {
                return true
            }

            return !modifiers.contains(where: \.isACLModifier)
        }
    }
}

private extension DeclModifierSyntax {
    var isACLModifier: Bool {
        let aclModifiers: Set<TokenKind> = [
            .keyword(.private),
            .keyword(.fileprivate),
            .keyword(.internal),
            .keyword(.public),
            .keyword(.open)
        ]

        return detail == nil && aclModifiers.contains(name.tokenKind)
    }
}
