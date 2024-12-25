import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct UnhandledThrowingTaskRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "unhandled_throwing_task",
        name: "Unhandled Throwing Task",
        description: """
            Errors thrown inside this task are not handled, which may be unexpected. \
            Handle errors inside the task, or use `try await` to access the Tasks value and handle errors. \
            See this forum thread for more details: \
            https://forums.swift.org/t/task-initializer-with-throwing-closure-swallows-error/56066
            """,
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
            """),
            Example("""
            let result = await Task {
              throw CancellationError()
            }.result
            """),
            Example("""
            func makeTask() -> Task<String, Error> {
              return Task {
                try await someThrowingFunction()
              }
            }
            """),
            Example("""
            func makeTask() -> Task<String, Error> {
              // Implicit return
              Task {
                try await someThrowingFunction()
              }
            }
            """),
            Example("""
            Task {
              return Result {
                  try someThrowingFunc()
              }
            }
            """),
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
            """),
            Example("""
            ↓Task {
              do {
                try foo()
              } catch {
                try bar()
              }
            }
            """),
            Example("""
            ↓Task {
              do {
                try foo()
              } catch {
                throw BarError()
              }
            }
            """),
            Example("""
            func doTask() {
              ↓Task {
                try await someThrowingFunction()
              }
            }
            """),
        ]
    )
}

private extension UnhandledThrowingTaskRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
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
            !(isAssigned || isValueOrResultAccessed || isReturnValue)
    }

    var isTaskWithImplicitErrorType: Bool {
        if let typeIdentifier = calledExpression.as(DeclReferenceExprSyntax.self),
           typeIdentifier.baseName.text == "Task" {
            return true
        }

        if let specializedExpression = calledExpression.as(GenericSpecializationExprSyntax.self),
           let typeIdentifier = specializedExpression.expression.as(DeclReferenceExprSyntax.self),
           typeIdentifier.baseName.text == "Task",
           let lastGeneric = specializedExpression.genericArgumentClause
            .arguments.last?.argument.as(IdentifierTypeSyntax.self),
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

    var isValueOrResultAccessed: Bool {
        guard let parent = parent?.as(MemberAccessExprSyntax.self) else {
            return false
        }

        return parent.declName.baseName.text == "value" || parent.declName.baseName.text == "result"
    }

    var doesThrow: Bool {
        ThrowsVisitor(viewMode: .sourceAccurate)
            .walk(tree: self, handler: \.doesThrow)
    }
}

/// If the `doesThrow` property is true after visiting, then this node throws an error that is "unhandled."
/// Try statements inside a `do` with a `catch` that handles all errors will not be marked as throwing.
private final class ThrowsVisitor: SyntaxVisitor {
    var doesThrow = false

    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        // No need to continue traversing if we already throw.
        if doesThrow {
            return .skipChildren
        }

        // If there are no catch clauses, visit children to see if there are any try expressions.
        guard let lastCatchClause = node.catchClauses.last else {
            return .visitChildren
        }

        let catchItems = lastCatchClause.catchItems

        // If we have a value binding pattern, only an IdentifierPatternSyntax will catch
        // any error; if it's not an IdentifierPatternSyntax, we need to visit children.
        if let pattern = catchItems.last?.pattern?.as(ValueBindingPatternSyntax.self),
           !pattern.pattern.is(IdentifierPatternSyntax.self) {
            return .visitChildren
        }

        // Check the catch clause tree for unhandled throws.
        if ThrowsVisitor(viewMode: .sourceAccurate).walk(tree: lastCatchClause, handler: \.doesThrow) {
            doesThrow = true
        }

        // We don't need to visit children of the `do` node, since all errors are handled by the catch.
        return .skipChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // No need to continue traversing if we already throw.
        if doesThrow {
            return .skipChildren
        }

        // Result initializers with trailing closures handle thrown errors.
        if let typeIdentifier = node.calledExpression.as(DeclReferenceExprSyntax.self),
           typeIdentifier.baseName.text == "Result",
           node.trailingClosure != nil {
            return .skipChildren
        }

        return .visitChildren
    }

    override func visitPost(_ node: TryExprSyntax) {
        if node.questionOrExclamationMark == nil {
            doesThrow = true
        }
    }

    override func visitPost(_: ThrowStmtSyntax) {
        doesThrow = true
    }
}

private extension SyntaxProtocol {
    var isExplicitReturnValue: Bool {
        parent?.is(ReturnStmtSyntax.self) == true
    }

    var isImplicitReturnValue: Bool {
        // 4th parent: FunctionDecl
        // 3rd parent: | CodeBlock
        // 2nd parent:   | CodeBlockItemList
        // 1st parent:     | CodeBlockItem
        // Current node:     | FunctionDeclSyntax
        guard
            let parentFunctionDecl = parent?.parent?.parent?.parent?.as(FunctionDeclSyntax.self),
            parentFunctionDecl.body?.statements.count == 1,
            parentFunctionDecl.signature.returnClause != nil
        else {
            return false
        }

        return true
    }

    var isReturnValue: Bool {
        isExplicitReturnValue || isImplicitReturnValue
    }
}
