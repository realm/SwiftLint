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
            Task {
              try? await myThrowingFunction()
            }
            """),
            Example("""
            Task {
              try! await myThrowingFunction()
            }
            """),
            Example("""
            Task<Void, String> {
              let text = try myThrowingFunction()
              return text
            }
            """),
            Example("""
            Task {
              do {
                try myThrowingFunction()
              } catch let e {
                print(e)
              }
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
            """),
            Example("""
            let task = Task {
              try await myThrowingFunction()
            }
            """),
            Example("""
            var task = Task {
              try await myThrowingFunction()
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
            """),
            Example("""
            ↓Task {
              do {
                throw FooError.bar
              }
            }
            """),
            Example("""
            ↓Task {
              throw FooError.bar
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
                    if node.parent?.is(InitializerClauseSyntax.self) == false {
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
}

private final class ThrowsVisitor: SyntaxVisitor {
    var doesThrow = false

    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        // If there are no catch clauses, visit children to see if there are any try expressions.
        guard let lastCatchClause = node.catchClauses?.last else {
            return .visitChildren
        }

        let catchItems = lastCatchClause.catchItems ?? []

        // If there are no catch items in the last clause,
        // we'll catch all errors thrown - all good here!
        if catchItems.isEmpty {
            return .skipChildren
        }

        // If we have a value binding pattern, only an IdentifierPatternSyntax
        // will catch any error, visit children for `try`s.
        guard let pattern = catchItems.last?.pattern?.as(ValueBindingPatternSyntax.self),
              pattern.valuePattern.is(IdentifierPatternSyntax.self) else {
            return .visitChildren
        }

        // Any `try`s are handled by the catch clauses, no throwing here!
        return .skipChildren
    }

    override func visitPost(_ node: TryExprSyntax) {
        if node.questionOrExclamationMark == nil {
            doesThrow = true
        }
    }

    override func visitPost(_ node: ThrowStmtSyntax) {
        doesThrow = true
    }
}
