import SwiftLintCore
import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct ToggleBoolRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "toggle_bool",
        name: "Toggle Bool",
        description: "Prefer `someBool.toggle()` over `someBool = !someBool`",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "isHidden.toggle()",
            "view.clipsToBounds.toggle()",
            "func foo() { abc.toggle() }",
            "view.clipsToBounds = !clipsToBounds",
            "disconnected = !connected",
            "result = !result.toggle()",
        ]),
        triggeringExamples: #examples([
            "↓isHidden = !isHidden",
            "↓view.clipsToBounds = !view.clipsToBounds",
            "func foo() { ↓abc = !abc }",
        ]),
        corrections: #corrections([
            "↓isHidden = !isHidden": "isHidden.toggle()",
            "↓view.clipsToBounds = !view.clipsToBounds": "view.clipsToBounds.toggle()",
            "func foo() { ↓abc = !abc }": "func foo() { abc.toggle() }",
        ])
    )
}

private extension ToggleBoolRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ExprListSyntax) {
            if node.hasToggleBoolViolation {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ExprListSyntax) -> ExprListSyntax {
            guard node.hasToggleBoolViolation, let firstExpr = node.first, let index = node.index(of: firstExpr) else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let elements = node
                .with(
                    \.[index],
                    "\(firstExpr.trimmed).toggle()"
                )
                .dropLast(2)
            let newNode = ExprListSyntax(elements)
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
            return super.visit(newNode)
        }
    }
}

private extension ExprListSyntax {
    var hasToggleBoolViolation: Bool {
        guard
            count == 3,
            dropFirst().first?.is(AssignmentExprSyntax.self) == true,
            last?.is(PrefixOperatorExprSyntax.self) == true,
            let lhs = first?.trimmedDescription,
            let rhs = last?.trimmedDescription,
            rhs == "!\(lhs)"
        else {
            return false
        }

        return true
    }
}
