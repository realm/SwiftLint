import SwiftSyntax

@SwiftSyntaxRule
struct UnusedOptionalBindingRule: Rule {
    var configuration = UnusedOptionalBindingConfiguration()

    static let description = RuleDescription(
        identifier: "unused_optional_binding",
        name: "Unused Optional Binding",
        description: "Prefer `!= nil` over `let _ =`",
        kind: .style,
        nonTriggeringExamples: #examples([
            "if let bar = Foo.optionalValue {}",
            "if let (_, second) = getOptionalTuple() {}",
            "if let (_, asd, _) = getOptionalTuple(), let bar = Foo.optionalValue {}",
            "if foo() { let _ = bar() }",
            "if foo() { _ = bar() }",
            "if case .some(_) = self {}",
            "if let point = state.find({ _ in true }) {}",
        ]),
        triggeringExamples: #examples([
            "if let ↓_ = Foo.optionalValue {}",
            "if let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {}",
            "guard let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {}",
            "if let (first, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}",
            "if let (first, _) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}",
            "if let (_, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}",
            "if let ↓(_, _, _) = getOptionalTuple(), let bar = Foo.optionalValue {}",
            "func foo() { if let ↓_ = bar {} }",
        ])
    )
}

private extension UnusedOptionalBindingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            guard let pattern = node.pattern.as(ExpressionPatternSyntax.self),
                  pattern.expression.isDiscardExpression else {
                return
            }

            if configuration.ignoreOptionalTry,
               let tryExpr = node.initializer?.value.as(TryExprSyntax.self),
               tryExpr.questionOrExclamationMark?.tokenKind == .postfixQuestionMark {
                return
            }

            violations.append(pattern.expression.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension ExprSyntax {
    var isDiscardExpression: Bool {
        if `is`(DiscardAssignmentExprSyntax.self) {
            return true
        }
        if let tuple = `as`(TupleExprSyntax.self) {
            return tuple.elements.allSatisfy(\.expression.isDiscardExpression)
        }

        return false
    }
}
