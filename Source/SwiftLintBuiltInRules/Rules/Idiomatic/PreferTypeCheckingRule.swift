import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(foldExpressions: true, explicitRewriter: true)
struct PreferTypeCheckingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_type_checking",
        name: "Prefer Type Checking",
        description: "Prefer `a is X` to `a as? X != nil`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let foo = bar as? Foo"),
            Example("bar is Foo"),
            Example("2*x is X"),
            Example("""
            if foo is Bar {
                doSomeThing()
            }
            """),
            Example("""
            if let bar = foo as? Bar {
                foo.run()
            }
            """),
        ],
        triggeringExamples: [
            Example("bar ↓as? Foo != nil"),
            Example("2*x as? X != nil"),
            Example("""
            if foo ↓as? Bar != nil {
                doSomeThing()
            }
            """),
        ],
        corrections: [
            Example("bar ↓as? Foo != nil"): Example("bar is Foo"),
            Example("2*x ↓as? X != nil"): Example("2*x is X"),
            Example("""
            if foo ↓as? Bar != nil {
                doSomeThing()
            }
            """): Example("""
            if foo is Bar {
                doSomeThing()
            }
            """),
        ]
    )
}

private extension PreferTypeCheckingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            if node.typeChecksWithAsCasting, let asExpr = node.leftOperand.as(AsExprSyntax.self) {
                violations.append(asExpr.asKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
            guard node.typeChecksWithAsCasting,
                  let asExpr = node.leftOperand.as(AsExprSyntax.self) else {
                return super.visit(node)
            }

            correctionPositions.append(asExpr.asKeyword.positionAfterSkippingLeadingTrivia)

            let expression = asExpr.expression.trimmed
            let type = asExpr.type.trimmed

            return ExprSyntax(stringLiteral: "\(expression) is \(type)")
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
        }
    }
}

private extension InfixOperatorExprSyntax {
    var typeChecksWithAsCasting: Bool {
        self.leftOperand.is(AsExprSyntax.self)
        && self.operator.as(BinaryOperatorExprSyntax.self)?.operator.tokenKind == .binaryOperator("!=")
        && self.rightOperand.is(NilLiteralExprSyntax.self)
    }
}
