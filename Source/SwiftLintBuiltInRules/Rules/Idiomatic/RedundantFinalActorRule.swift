import SwiftSyntax

@SwiftSyntaxRule(correctable: true)
struct RedundantFinalActorRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_final_actor",
        name: "Redundant Final Actor",
        description: "Actors are implicitly `final`; the `final` modifier is redundant.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("actor DataStorage {}"),
            Example("""
            actor Counter {
                var count = 0
            }
            """),
            Example("final class Foo {}"),
            Example("""
            public actor Scheduler {
                func schedule() {}
            }
            """),
        ],
        triggeringExamples: [
            Example("↓final actor DataStorage {}"),
            Example("""
            ↓final actor Counter {
                var count = 0
            }
            """),
            Example("public ↓final actor Scheduler {}"),
        ],
        corrections: [
            Example("↓final actor DataStorage {}"): Example("actor DataStorage {}"),
            Example("""
            ↓final actor Counter {
                var count = 0
            }
            """): Example("""
            actor Counter {
                var count = 0
            }
            """),
            Example("public ↓final actor Scheduler {}"): Example("public actor Scheduler {}"),
        ]
    )
}

private extension RedundantFinalActorRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ActorDeclSyntax) {
            guard let finalModifier = node.modifiers.first(where: { $0.name.tokenKind == .keyword(.final) }) else {
                return
            }
            // Find the position just after this modifier (start of next modifier or actor keyword)
            // to correctly capture any trailing whitespace in the correction range.
            let endPosition = node.modifiers
                .dropFirst(node.modifiers.distance(from: node.modifiers.startIndex,
                                                   to: node.modifiers.firstIndex(where: { $0.name.tokenKind == .keyword(.final) })!) + 1)
                .first
                .map { $0.positionAfterSkippingLeadingTrivia }
                ?? node.actorKeyword.positionAfterSkippingLeadingTrivia
            violations.append(
                ReasonedRuleViolation(
                    position: finalModifier.positionAfterSkippingLeadingTrivia,
                    correction: .init(
                        start: finalModifier.positionAfterSkippingLeadingTrivia,
                        end: endPosition,
                        replacement: ""
                    )
                )
            )
        }
    }
}
