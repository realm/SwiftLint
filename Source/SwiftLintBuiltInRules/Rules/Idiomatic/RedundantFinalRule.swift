import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct RedundantFinalRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_final",
        name: "Redundant Final",
        description: "`final` is redundant",
        rationale: """
            Actors in Swift currently do not support inheritance, making `final` redundant on both actor declarations
            and their members. Note that this may change in future Swift versions if actor inheritance is introduced.

            Additionally, `final` is redundant on members of a `final class` since they cannot be overridden.
            """,
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "actor MyActor {}",
            "final class MyClass {}",
            """
            @globalActor
            actor MyGlobalActor {}
            """,
            """
            actor MyActor {
                func doWork() {}
                final class C1 {}
                class C2 {
                    final func doWork() {}
                }
            }
            """,
            """
            class MyClass {
                final func doWork() {}
            }
            """,
        ]),
        triggeringExamples: #examples([
            "↓final actor MyActor {}",
            "public ↓final actor DataStore {}",
            """
            @globalActor
            ↓final actor MyGlobalActor {}
            """,
            """
            actor MyActor {
                ↓final func doWork() {}
            }
            """,
            """
            actor MyActor {
                ↓final var value: Int { 0 }
            }
            """,
            """
            final class C1 {
                ↓final actor A1 {
                    ↓final func doWork() {}
                }
                ↓final func doWork() {}
                final class C2 {
                    ↓final func doWork() {}
                }
            }
            """,
        ]),
        corrections: #examplesDictionary([
            "final actor MyActor {}":
                "actor MyActor {}",
            "public final actor DataStore {}":
                "public actor DataStore {}",
            "actor MyActor { final func doWork() {}}":
                "actor MyActor { func doWork() {}}",
        ])
    )
}

private extension RedundantFinalRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var finalTypeStack = Stack<Bool>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visit(_: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            finalTypeStack.push(true)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if let finalModifier = node.modifiers.modifier(with: .final) {
                addViolation(for: finalModifier)
            }
            finalTypeStack.pop()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            finalTypeStack.push(node.modifiers.contains(keyword: .final))
            return .visitChildren
        }

        override func visitPost(_: ClassDeclSyntax) {
            finalTypeStack.pop()
        }

        override func visit(_: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            finalTypeStack.push(false)
            return .visitChildren
        }

        override func visitPost(_: EnumDeclSyntax) {
            finalTypeStack.pop()
        }

        override func visit(_: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            finalTypeStack.push(false)
            return .visitChildren
        }

        override func visitPost(_: ExtensionDeclSyntax) {
            finalTypeStack.pop()
        }

        override func visit(_: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            finalTypeStack.push(false)
            return .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            finalTypeStack.pop()
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if finalTypeStack.peek() == true, let finalModifier = node.modifiers.modifier(with: .final) {
                addViolation(for: finalModifier)
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            if finalTypeStack.peek() == true, let finalModifier = node.modifiers.modifier(with: .final) {
                addViolation(for: finalModifier)
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if finalTypeStack.peek() == true, let finalModifier = node.modifiers.modifier(with: .final) {
                addViolation(for: finalModifier)
            }
        }

        private func addViolation(for finalModifier: DeclModifierSyntax) {
            let start = finalModifier.positionAfterSkippingLeadingTrivia
            violations.append(.init(
                position: start,
                correction: .init(
                    start: start,
                    end: finalModifier.endPosition,
                    replacement: ""
                )
            ))
        }
    }
}
