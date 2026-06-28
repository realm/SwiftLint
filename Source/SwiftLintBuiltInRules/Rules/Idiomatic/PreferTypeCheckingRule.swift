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
        nonTriggeringExamples: #examples([
            "let foo = bar as? Foo",
            "bar is Foo",
            "2*x is X",
            """
            if foo is Bar {
                doSomeThing()
            }
            """,
            """
            if let bar = foo as? Bar {
                foo.run()
            }
            """,
            "bar as Foo != nil",
            "nil != bar as Foo",
            "bar as Foo? != nil",
            "bar as? Foo? != nil",
        ]),
        triggeringExamples: #examples([
            "bar ↓as? Foo != nil",
            "2*x as? X != nil",
            """
            if foo ↓as? Bar != nil {
                doSomeThing()
            }
            """,
            "nil != bar ↓as? Foo",
            "nil != 2*x ↓as? X",
        ]),
        corrections: #examplesDictionary([
            "bar ↓as? Foo != nil": "bar is Foo",
            "nil != bar ↓as? Foo": "bar is Foo",
            "2*x ↓as? X != nil": "2*x is X",
            """
            if foo ↓as? Bar != nil {
                doSomeThing()
            }
            """: """
            if foo is Bar {
                doSomeThing()
            }
            """,
        ])
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
            numberOfCorrections += 1
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
           `operator`.as(BinaryOperatorExprSyntax.self)?.operator.tokenKind == .binaryOperator("!="),
           rightOperand.is(NilLiteralExprSyntax.self) || leftOperand.is(NilLiteralExprSyntax.self) {
            asExpr
        } else {
            nil
        }
    }
}
