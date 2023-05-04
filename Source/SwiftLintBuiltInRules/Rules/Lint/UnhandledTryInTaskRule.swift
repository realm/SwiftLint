import SwiftSyntax

struct UnhandledThrowingTaskRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.error)

    static let description = RuleDescription(
        identifier: "unhandled_throwing_task",
        name: "Unhandled Throwing Task",
        description: "Errors thrown inside this task are not handled",
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
            """),
            Example("""
            try await Task {
              try await myThrowingFunction()
            }.value
            """),
            Example("""
            executor.task = Task {
              try await isolatedOpen(.init(executor.asUnownedSerialExecutor()))
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
            """),
            Example("""
            ↓Task<_, _> {
              throw FooError.bar
            }
            """),
            Example("""
            ↓Task<Void,_> {
              throw FooError.bar
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension UnhandledThrowingTaskRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.hasViolation {
                violations.append(node.calledExpression.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension FunctionCallExprSyntax {
    var hasViolation: Bool {
        isTaskWithImplicitErrorType &&
            doesThrow &&
            !(isAssigned || isValueAccessed)
    }

    var isTaskWithImplicitErrorType: Bool {
        if let typeIdentifier = calledExpression.as(IdentifierExprSyntax.self),
           typeIdentifier.identifier.text == "Task" {
            return true
        }

        if let specializedExpression = calledExpression.as(SpecializeExprSyntax.self),
           let typeIdentifier = specializedExpression.expression.as(IdentifierExprSyntax.self),
           typeIdentifier.identifier.text == "Task",
           let lastGeneric = specializedExpression.genericArgumentClause
            .arguments.last?.argumentType.as(SimpleTypeIdentifierSyntax.self),
           lastGeneric.typeName == "_" {
            return true
        }

        return false
    }

    var isAssigned: Bool {
        guard let parent else {
            return false
        }

        if parent.is(InitializerClauseSyntax.self) {
            return true
        }

        if let list = parent.as(ExprListSyntax.self),
           list.contains(where: { $0.is(AssignmentExprSyntax.self) }) {
            return true
        }

        return false
    }

    var isValueAccessed: Bool {
        guard let parent = parent?.as(MemberAccessExprSyntax.self) else {
            return false
        }

        return parent.name.text == "value"
    }

    var doesThrow: Bool {
        ThrowsVisitor(viewMode: .sourceAccurate)
            .walk(tree: self, handler: \.doesThrow)
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
