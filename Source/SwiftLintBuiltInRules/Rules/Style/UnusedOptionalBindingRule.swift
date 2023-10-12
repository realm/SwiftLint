import SwiftSyntax

struct UnusedOptionalBindingRule: SwiftSyntaxRule {
    var configuration = UnusedOptionalBindingConfiguration()

    static let description = RuleDescription(
        identifier: "unused_optional_binding",
        name: "Unused Optional Binding",
        description: "Prefer `!= nil` over `let _ =`",
        kind: .style,
        nonTriggeringExamples: [
            Example("if let bar = Foo.optionalValue {}"),
            Example("if let (_, second) = getOptionalTuple() {}"),
            Example("if let (_, asd, _) = getOptionalTuple(), let bar = Foo.optionalValue {}"),
            Example("if foo() { let _ = bar() }"),
            Example("if foo() { _ = bar() }"),
            Example("if case .some(_) = self {}"),
            Example("if let point = state.find({ _ in true }) {}")
        ],
        triggeringExamples: [
            Example("if let ↓_ = Foo.optionalValue {}"),
            Example("if let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {}"),
            Example("guard let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {}"),
            Example("if let (first, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}"),
            Example("if let (first, _) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}"),
            Example("if let (_, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {}"),
            Example("if let ↓(_, _, _) = getOptionalTuple(), let bar = Foo.optionalValue {}"),
            Example("func foo() { if let ↓_ = bar {} }")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(ignoreOptionalTry: configuration.ignoreOptionalTry)
    }
}

private extension UnusedOptionalBindingRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let ignoreOptionalTry: Bool

        init(ignoreOptionalTry: Bool) {
            self.ignoreOptionalTry = ignoreOptionalTry
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            guard let pattern = node.pattern.as(ExpressionPatternSyntax.self),
                  pattern.expression.isDiscardExpression else {
                return
            }

            if ignoreOptionalTry,
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
        if self.is(DiscardAssignmentExprSyntax.self) {
            return true
        } else if let tuple = self.as(TupleExprSyntax.self) {
            return tuple.elements.allSatisfy { elem in
                elem.expression.isDiscardExpression
            }
        }

        return false
    }
}
