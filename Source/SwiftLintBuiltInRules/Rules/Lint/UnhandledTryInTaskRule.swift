import SwiftSyntax

struct UnhandledTryInTaskRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.error)

    static let description = RuleDescription(
        identifier: "unhandled_try_in_task",
        name: "Unhandled Try in Task",
        description: "Errors thrown inside of this task are not handled",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            Task<Void, Never> {
              try await myThrowingFunction()
            }
            """),
            Example("""
            Task<Void, String> {
              let text = try myThrowingFunction()
              return text
            }
            """),
            Example("""
            func someFunction() throws {
              Task {
                anotherFunction()
                do {
                  try myThrowingFunction()
                } catch {
                  print(error)
                }
              }

              try something()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓Task {
              try await myThrowingFunction()
            }
            """),
            Example("""
            ↓Task {
              let text = try myThrowingFunction()
              return text
            }
            """),
            Example("""
            ↓Task {
              do {
                try myThrowingFunction()
              }
            }
            """),
            Example("""
            ↓Task {
              do {
                try myThrowingFunction()
              } catch let e as FooError {
                print(e)
              }
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension UnhandledTryInTaskRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let typeIdentifier = node.calledExpression.as(IdentifierExprSyntax.self) {
                if typeIdentifier.identifier.text == "Task" {
                    let throwsVisitor = ThrowsVisitor(viewMode: .sourceAccurate)
                    throwsVisitor.walk(node)
                    if throwsVisitor.doesThrow {
                        violations.append(node.calledExpression.positionAfterSkippingLeadingTrivia)
                    }
                }
            }
        }
    }
}

private final class ThrowsVisitor: SyntaxVisitor {
    var doesThrow = false

    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        // If there are no catch clauses, visit children to see if there are any try expressions.
        guard let catchClauses = node.catchClauses else {
            return .visitChildren
        }

        // If none of the catch clauses handle all items, then we also need to visit children.
        guard catchClauses.contains(where: { ($0.catchItems ?? []).isEmpty }) else {
            return .visitChildren
        }

        // Any `try`s are handled by the catch clauses, no throwing here!
        return .skipChildren
    }

    override func visitPost(_ node: TryExprSyntax) {
        doesThrow = true
    }
}
