import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct RedundantFinalActorRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_final_actor",
        name: "Redundant Final on Actor",
        description: "`final` is redundant on an actor declaration because actors cannot be subclassed",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("actor MyActor {}"),
            Example("final class MyClass {}"),
            Example("""
            @globalActor
            actor MyGlobalActor {}
            """),
        ],
        triggeringExamples: [
            Example("↓final actor MyActor {}"),
            Example("public ↓final actor DataStore {}"),
            Example("""
            @globalActor
            ↓final actor MyGlobalActor {}
            """),
        ],
        corrections: [
            Example("final actor MyActor {}"):
                Example("actor MyActor {}"),
            Example("public final actor DataStore {}"):
                Example("public actor DataStore {}"),
        ]
    )
}

private extension RedundantFinalActorRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ActorDeclSyntax) {
            if let finalModifier = node.modifiers.first(where: { $0.name.text == "final" }) {
                violations.append(finalModifier.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
            guard let finalIndex = node.modifiers.firstIndex(where: { $0.name.text == "final" }) else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            var modifiers = node.modifiers
            modifiers.remove(at: finalIndex)
            // If no modifiers remain, preserve the leading trivia on the actor keyword
            var result = node.with(\.modifiers, modifiers)
            if modifiers.isEmpty {
                let leadingTrivia = node.modifiers[finalIndex].leadingTrivia
                result = result.with(\.actorKeyword.leadingTrivia, leadingTrivia)
            }
            return super.visit(result)
        }
    }
}
