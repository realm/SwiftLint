import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
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
            guard let finalModifier = node.modifiers.first(where: { $0.name.text == "final" }) else {
                return
            }
            let start = finalModifier.positionAfterSkippingLeadingTrivia
            // endPosition includes trailing trivia (the space after "final")
            let end = finalModifier.endPosition
            violations.append(
                ReasonedRuleViolation(
                    position: start,
                    correction: .init(
                        start: start,
                        end: end,
                        replacement: ""
                    )
                )
            )
        }
    }
}
