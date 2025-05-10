import SwiftSyntax

@SwiftSyntaxRule
struct NotificationCenterDetachmentRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "notification_center_detachment",
        name: "Notification Center Detachment",
        description: "An object should only remove itself as an observer in `deinit`",
        kind: .lint,
        nonTriggeringExamples: NotificationCenterDetachmentRuleExamples.nonTriggeringExamples,
        triggeringExamples: NotificationCenterDetachmentRuleExamples.triggeringExamples
    )
}

private extension NotificationCenterDetachmentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.isNotificationCenterDettachmentCall,
                  let arg = node.arguments.first,
                  arg.label == nil,
                  let expr = arg.expression.as(DeclReferenceExprSyntax.self),
                  expr.baseName.tokenKind == .keyword(.self) else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visit(_: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}

private extension FunctionCallExprSyntax {
    var isNotificationCenterDettachmentCall: Bool {
        guard trailingClosure == nil,
              arguments.count == 1,
              let expr = calledExpression.as(MemberAccessExprSyntax.self),
              expr.declName.baseName.text == "removeObserver",
              let baseExpr = expr.base?.as(MemberAccessExprSyntax.self),
              baseExpr.declName.baseName.text == "default",
              baseExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "NotificationCenter" else {
            return false
        }

        return true
    }
}
