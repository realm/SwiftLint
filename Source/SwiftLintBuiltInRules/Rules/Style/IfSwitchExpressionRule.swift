import Foundation
import SwiftSyntax
import SwiftLintCore


@SwiftSyntaxRule(explicitRewriter: true)
struct IfSwitchExpressionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "if_switch_expression",
        name: "If and Switch Expression",
        description: "Enforce the of if and switch statements when they are allowed ",
        kind: .style,
        nonTriggeringExamples: IfSwitchExpressionRuleExamples.nonTriggeringExamples,
        triggeringExamples: IfSwitchExpressionRuleExamples.triggeringExamples
    )
}
private extension IfSwitchExpressionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
            violations.append(node.positionAfterSkippingLeadingTrivia)
            return .skipChildren
        }
        override func visit(_ node: SwitchCaseListSyntax) -> SyntaxVisitorContinueKind {
            violations.append(node.positionAfterSkippingLeadingTrivia)
            return .skipChildren
        }
    }
}
