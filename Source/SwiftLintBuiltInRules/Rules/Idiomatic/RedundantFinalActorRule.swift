import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct RedundantFinalActorRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_final_actor",
        name: "Redundant Final on Actor",
        description: "`final` is redundant on an actor declaration and its members because actors cannot be subclassed",
        rationale: """
            Actors in Swift currently do not support inheritance, making `final` redundant \
            on both actor declarations and their members. Note that this may change in future \
            Swift versions if actor inheritance is introduced.
            """,
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("actor MyActor {}"),
            Example("final class MyClass {}"),
            Example("""
            @globalActor
            actor MyGlobalActor {}
            """),
            Example("""
            actor MyActor {
                func doWork() {}
                var value: Int { 0 }
            }
            """),
            Example("""
            class MyClass {
                final func doWork() {}
            }
            """),
        ],
        triggeringExamples: [
            Example("↓final actor MyActor {}"),
            Example("public ↓final actor DataStore {}"),
            Example("""
            @globalActor
            ↓final actor MyGlobalActor {}
            """),
            Example("""
            actor MyActor {
                ↓final func doWork() {}
            }
            """),
            Example("""
            actor MyActor {
                ↓final var value: Int { 0 }
            }
            """),
        ],
        corrections: [
            Example("final actor MyActor {}"):
                Example("actor MyActor {}"),
            Example("public final actor DataStore {}"):
                Example("public actor DataStore {}"),
            Example("actor MyActor {\n    final func doWork() {}\n}"):
                Example("actor MyActor {\n    func doWork() {}\n}"),
        ]
    )
}

private extension RedundantFinalActorRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var insideActor = false

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            insideActor = true
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if let finalModifier = node.modifiers.first(where: { $0.name.text == "final" }) {
                addViolation(for: finalModifier)
            }
            insideActor = false
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard insideActor,
                  let finalModifier = node.modifiers.first(where: { $0.name.text == "final" }) else {
                return
            }
            addViolation(for: finalModifier)
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard insideActor,
                  let finalModifier = node.modifiers.first(where: { $0.name.text == "final" }) else {
                return
            }
            addViolation(for: finalModifier)
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            guard insideActor,
                  let finalModifier = node.modifiers.first(where: { $0.name.text == "final" }) else {
                return
            }
            addViolation(for: finalModifier)
        }

        // Don't descend into nested classes where `final` is meaningful
        override func visit(_: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        private func addViolation(for finalModifier: DeclModifierSyntax) {
            let start = finalModifier.positionAfterSkippingLeadingTrivia
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
