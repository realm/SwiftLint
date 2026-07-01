import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct RedundantSendableRule: Rule {
    var configuration = RedundantSendableConfiguration()

    static let description = RuleDescription(
        identifier: "redundant_sendable",
        name: "Redundant Sendable",
        description: "Sendable conformance is redundant on an actor-isolated type",
        kind: .lint,
        nonTriggeringExamples: #examples([
            "struct S: Sendable {}",
            "class C: Sendable {}",
            "actor A {}",
            "@MainActor struct S {}",
            "@MyActor enum E: Sendable { case a }",
            "@MainActor protocol P: Sendable {}",
        ]),
        triggeringExamples: #examples([
            "@MainActor struct ↓S: Sendable {}",
            "actor ↓A: Sendable {}",
            "@MyActor enum ↓E: Sendable { case a }".configuration(["global_actors": ["MyActor"]]),
        ]),
        corrections: #examplesDictionary([
            "@MainActor struct S: Sendable {}":
                "@MainActor struct S {}",
            "actor A: Sendable /* trailing comment */{}":
                "actor A /* trailing comment */{}",
            "@MyActor enum E: Sendable { case a }".configuration(["global_actors": ["MyActor"]]):
                "@MyActor enum E { case a }",
            """
                actor A: B, Sendable, C // comment
                {}
                """:
                """
                    actor A: B, C // comment
                    {}
                    """,
            "@MainActor struct P: A, Sendable {}":
                "@MainActor struct P: A {}",
        ])
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
                numberOfCorrections += 1
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

        override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            super.visit(removeRedundantSendable(from: node))
        }

        private func removeRedundantSendable<T: DeclGroupSyntax & NamedDeclSyntax>(from decl: T) -> T {
            if decl.conformsToSendable, decl.isIsolatedToActor(actors: configuration.globalActors) {
                numberOfCorrections += 1
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
        if let lastType = inheritedTypes.last, let lastIndex = inheritedTypes.index(of: lastType) {
            return with(\.inheritanceClause, inheritanceClause
                .with(\.inheritedTypes, inheritedTypes.with(\.[lastIndex], lastType.withoutComma)))
        }
        return with(\.inheritanceClause, nil)
            .with(\.name.trailingTrivia, inheritanceClause.leadingTrivia + inheritanceClause.trailingTrivia)
    }
}

private extension InheritedTypeSyntax {
    var isSendable: Bool {
        type.as(IdentifierTypeSyntax.self)?.name.text == "Sendable"
    }

    var withoutComma: InheritedTypeSyntax {
        with(\.trailingComma, nil)
            .with(\.trailingTrivia, trailingTrivia)
    }
}
