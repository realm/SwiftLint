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
            Example("bar as Foo != nil"),
            Example("nil != bar as Foo"),
            Example("bar as Foo? != nil"),
            Example("bar as? Foo? != nil"),
        ],
        triggeringExamples: [
            Example("bar ↓as? Foo != nil"),
            Example("2*x as? X != nil"),
            Example("""
            if foo ↓as? Bar != nil {
                doSomeThing()
            }
            """),
            Example("nil != bar ↓as? Foo"),
            Example("nil != 2*x ↓as? X"),
        ],
        corrections: [
            Example("bar ↓as? Foo != nil"): Example("bar is Foo"),
            Example("nil != bar ↓as? Foo"): Example("bar is Foo"),
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
            if let asExpr = node.asExprWithOptionalTypeChecking {
                violations.append(asExpr.asKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
            guard let asExpr = node.asExprWithOptionalTypeChecking else {
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
    var asExprWithOptionalTypeChecking: AsExprSyntax? {
        if let asExpr = leftOperand.as(AsExprSyntax.self) ?? rightOperand.as(AsExprSyntax.self),
           asExpr.questionOrExclamationMark?.tokenKind == .postfixQuestionMark,
           !asExpr.type.is(OptionalTypeSyntax.self),
           self.operator.as(BinaryOperatorExprSyntax.self)?.operator.tokenKind == .binaryOperator("!="),
           rightOperand.is(NilLiteralExprSyntax.self) || leftOperand.is(NilLiteralExprSyntax.self) {
            asExpr
        } else {
            nil
        }
    }
}
