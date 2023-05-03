import SwiftSyntax

struct ExplicitTryTaskRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    static let description = RuleDescription(
        identifier: "explicit_try_task",
        name: "Explicit Try Task",
        description: "TODO: Fill out this rule's description",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            Task<Void, Never> {
              try foo()
            }
            """),
            Example("""
            Task<Void, Never> {
              helloWorld()
              something {

              }
              try foo()
            }
            """),
            Example("""
            Foo {
              Task {
                helloWorld()
                something {

                }
              }

              try something()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓Task {
              try foo()
            }
            """),
            Example("""
            ↓Task {
              helloWorld()
              something {

              }
              try foo()
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ExplicitTryTaskRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            // TODO: Replace 'trimmedDescription' with more optimized check
            if node.calledExpression.trimmedDescription == "Task" {
                let tryVisitor = TryVisitor(viewMode: .sourceAccurate)
                tryVisitor.walk(node)
                if tryVisitor.hasTry {
                    violations.append(node.calledExpression.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}

private final class TryVisitor: SyntaxVisitor {
    var hasTry = false
    override func visitPost(_ node: TryExprSyntax) {
        hasTry = true
    }
}
