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
        nonTriggeringExamples: [
            Example("isHidden.toggle()"),
            Example("view.clipsToBounds.toggle()"),
            Example("func foo() { abc.toggle() }"),
            Example("view.clipsToBounds = !clipsToBounds"),
            Example("disconnected = !connected"),
            Example("result = !result.toggle()"),
        ],
        triggeringExamples: [
            Example("↓isHidden = !isHidden"),
            Example("↓view.clipsToBounds = !view.clipsToBounds"),
            Example("func foo() { ↓abc = !abc }"),
        ],
        corrections: [
            Example("↓isHidden = !isHidden"): Example("isHidden.toggle()"),
            Example("↓view.clipsToBounds = !view.clipsToBounds"): Example("view.clipsToBounds.toggle()"),
            Example("func foo() { ↓abc = !abc }"): Example("func foo() { abc.toggle() }"),
        ]
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
            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
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
