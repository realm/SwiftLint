import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct RedundantSendableRule: Rule {
    var configuration = RedundantSendableConfiguration()

    static let description = RuleDescription(
        identifier: "redundant_sendable",
        name: "Redundant Sendable",
        description: "Sendable conformance is redundant on an actor-isolated type",
        kind: .lint,
        nonTriggeringExamples: [
            Example("struct S: Sendable {}"),
            Example("class C: Sendable {}"),
            Example("actor A {}"),
            Example("@MainActor struct S {}"),
            Example("@MyActor enum E: Sendable { case a }"),
        ],
        triggeringExamples: [
            Example("@MainActor struct ↓S: Sendable {}"),
            Example("actor ↓A: Sendable {}"),
            Example("@MyActor enum ↓E: Sendable { case a }", configuration: ["global_actors": ["MyActor"]]),
        ],
        corrections: [
            Example("@MainActor struct S: Sendable {}"):
                Example("@MainActor struct S {}"),
            Example("actor A: Sendable {}"):
                Example("actor A {}"),
            Example("@MyActor enum E: Sendable { case a }", configuration: ["global_actors": ["MyActor"]]):
                Example("@MyActor enum E { case a }"),
            Example("actor A: B, Sendable, C {}"):
                Example("actor A: B, C {}"),
        ]
    )
}

private extension RedundantSendableRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ActorDeclSyntax) {
            if node.conformsToSendable {
                violations.append(at: node.name.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            collectViolations(in: node)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            collectViolations(in: node)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            collectViolations(in: node)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            collectViolations(in: node)
        }

        private func collectViolations(in decl: some DeclGroupSyntax & NamedDeclSyntax) {
            if decl.conformsToSendable, decl.isIsolatedToActor(actors: configuration.globalActors) {
                violations.append(at: decl.name.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
            if node.conformsToSendable {
                correctionPositions.append(node.name.positionAfterSkippingLeadingTrivia)
                return super.visit(node.withoutSendable)
            }
            return super.visit(node)
        }

        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            super.visit(removeRedundantSendable(from: node))
        }

        override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
            super.visit(removeRedundantSendable(from: node))
        }

        override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
            super.visit(removeRedundantSendable(from: node))
        }

        override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            super.visit(removeRedundantSendable(from: node))
        }

        private func removeRedundantSendable<T: DeclGroupSyntax & NamedDeclSyntax>(from decl: T) -> T {
            if decl.conformsToSendable, decl.isIsolatedToActor(actors: configuration.globalActors) {
                correctionPositions.append(decl.name.positionAfterSkippingLeadingTrivia)
                return decl.withoutSendable
            }
            return decl
        }
    }
}

private extension DeclGroupSyntax where Self: NamedDeclSyntax {
    var conformsToSendable: Bool {
        inheritanceClause?.inheritedTypes.contains(where: \.isSendable) == true
    }

    func isIsolatedToActor(actors: Set<String>) -> Bool {
        attributes.contains(attributeNamed: "MainActor") || actors.contains { attributes.contains(attributeNamed: $0) }
    }

    var withoutSendable: Self {
        guard let inheritanceClause else {
            return self
        }
        let inheritedTypes = inheritanceClause.inheritedTypes.filter { !$0.isSendable }
        if inheritedTypes.isEmpty {
            return with(\.inheritanceClause, nil)
                .with(\.name.trailingTrivia, inheritanceClause.leadingTrivia + inheritanceClause.trailingTrivia)
        }
        return with(\.inheritanceClause, inheritanceClause
            .with(\.inheritedTypes, inheritedTypes))
    }
}

private extension InheritedTypeSyntax {
    var isSendable: Bool {
        type.as(IdentifierTypeSyntax.self)?.name.text == "Sendable"
    }
}
