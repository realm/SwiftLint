import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PreferScaledToFitRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_scaled_to_fit",
        name: "Prefer Scaled To Fit",
        description: "Prefer `scaledToFit()` or `scaledToFill()` over `aspectRatio(contentMode:)` with a constant content mode",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("view.aspectRatio(ratio, contentMode: .fit)"),
            Example("view.aspectRatio(ratio, contentMode: .fill)"),
            Example("view.aspectRatio(contentMode: contentMode)"),
            Example("view.aspectRatio(contentMode: shouldFit ? .fit : .fill)"),
            Example("view.scaledToFit()"),
            Example("view.scaledToFill()"),
        ],
        triggeringExamples: [
            Example("view.↓aspectRatio(contentMode: .fit)"),
            Example("view.↓aspectRatio(contentMode: .fill)"),
            Example("↓aspectRatio(contentMode: .fit)"),
            Example("↓aspectRatio(contentMode: .fill)"),
        ]
    )
}

private extension PreferScaledToFitRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let functionName: String
            let violationPosition: AbsolutePosition

            if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) {
                functionName = memberAccess.declName.baseName.text
                violationPosition = memberAccess.declName.baseName.positionAfterSkippingLeadingTrivia
            } else if let declRef = node.calledExpression.as(DeclReferenceExprSyntax.self) {
                functionName = declRef.baseName.text
                violationPosition = declRef.baseName.positionAfterSkippingLeadingTrivia
            } else {
                return
            }

            guard functionName == "aspectRatio" else {
                return
            }

            guard
                node.arguments.count == 1,
                let argument = node.arguments.first,
                argument.label?.text == "contentMode"
            else {
                return
            }

            guard
                let memberValue = argument.expression.as(MemberAccessExprSyntax.self),
                let valueName = memberValue.declName.baseName.text as String?,
                valueName == "fit" || valueName == "fill"
            else {
                return
            }

            violations.append(violationPosition)
        }
    }
}
