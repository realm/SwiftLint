import SwiftSyntax

struct NotificationCenterDetachmentRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "notification_center_detachment",
        name: "Notification Center Detachment",
        description: "An object should only remove itself as an observer in `deinit`",
        kind: .lint,
        nonTriggeringExamples: NotificationCenterDetachmentRuleExamples.nonTriggeringExamples,
        triggeringExamples: NotificationCenterDetachmentRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NotificationCenterDetachmentRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.isNotificationCenterDettachmentCall,
                  let arg = node.argumentList.first,
                  arg.label == nil,
                  let expr = arg.expression.as(IdentifierExprSyntax.self),
                  expr.identifier.tokenKind == .keyword(.self) else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}

private extension FunctionCallExprSyntax {
    var isNotificationCenterDettachmentCall: Bool {
        guard trailingClosure == nil,
              argumentList.count == 1,
              let expr = calledExpression.as(MemberAccessExprSyntax.self),
              expr.name.text == "removeObserver",
              let baseExpr = expr.base?.as(MemberAccessExprSyntax.self),
              baseExpr.name.text == "default",
              baseExpr.base?.as(IdentifierExprSyntax.self)?.identifier.text == "NotificationCenter" else {
            return false
        }

        return true
    }
}
