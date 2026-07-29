import SwiftLintCore
import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(explicitRewriter: true)
struct LegacySwiftUIAspectRatioRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "legacy_swiftui_aspect_ratio",
        name: "Legacy SwiftUI Aspect Ratio",
        description: "Prefer `scaledToFit()` or `scaledToFill()` over " +
        "`aspectRatio(contentMode:)` with a constant content mode",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "view.aspectRatio(ratio, contentMode: .fit)",
            "view.aspectRatio(ratio, contentMode: .fill)",
            "view.aspectRatio(contentMode: contentMode)",
            "view.aspectRatio(contentMode: shouldFit ? .fit : .fill)",
            "view.aspectRatio(contentMode: CustomMode.fit)",
            "view.scaledToFit()",
            "view.scaledToFill()",
        ]),
        triggeringExamples: #examples([
            "view.↓aspectRatio(contentMode: .fit)",
            "view.↓aspectRatio(contentMode: .fill)",
            "view.↓aspectRatio(contentMode: ContentMode.fit)",
            "view.↓aspectRatio(contentMode: ContentMode.fill)",
            "↓aspectRatio(contentMode: .fit)",
            "↓aspectRatio(contentMode: .fill)",
        ]),
        corrections: #corrections([
            "view.↓aspectRatio(contentMode: .fit)": "view.scaledToFit()",
            "view.↓aspectRatio(contentMode: .fill)": "view.scaledToFill()",
            "view.↓aspectRatio(contentMode: ContentMode.fit)": "view.scaledToFit()",
            "view.↓aspectRatio(contentMode: ContentMode.fill)": "view.scaledToFill()",
            "↓aspectRatio(contentMode: .fit)": "scaledToFit()",
            "↓aspectRatio(contentMode: .fill)": "scaledToFill()",
        ])
    )
}

private extension LegacySwiftUIAspectRatioRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let violation = node.legacySwiftUIAspectRatioViolation else { return }
            violations.append(violation.position)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard let violation = node.legacySwiftUIAspectRatioViolation else {
                return super.visit(node)
            }

            numberOfCorrections += 1
            let calledExpression: ExprSyntax =
                if let base = violation.calledExpressionBase {
                    "\(base.trimmed).\(raw: violation.replacementFunctionName)"
                } else {
                    "\(raw: violation.replacementFunctionName)"
                }

            let newNode = node
                .with(\.calledExpression, calledExpression)
                .with(\.leftParen, node.leftParen?.with(\.trailingTrivia, []))
                .with(\.arguments, [])
                .with(\.rightParen, node.rightParen?.with(\.leadingTrivia, []))
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)

            return super.visit(newNode)
        }
    }
}

private struct LegacySwiftUIAspectRatioViolation {
    let position: AbsolutePosition
    let calledExpressionBase: ExprSyntax?
    let replacementFunctionName: String
}

private extension FunctionCallExprSyntax {
    var legacySwiftUIAspectRatioViolation: LegacySwiftUIAspectRatioViolation? {
        let violationPosition: AbsolutePosition
        let calledExpressionBase: ExprSyntax?

        if let memberAccess = calledExpression.as(MemberAccessExprSyntax.self) {
            guard memberAccess.declName.baseName.text == "aspectRatio" else {
                return nil
            }
            violationPosition = memberAccess.declName.baseName.positionAfterSkippingLeadingTrivia
            calledExpressionBase = memberAccess.base
        } else if let declRef = calledExpression.as(DeclReferenceExprSyntax.self) {
            guard declRef.baseName.text == "aspectRatio" else {
                return nil
            }
            violationPosition = declRef.baseName.positionAfterSkippingLeadingTrivia
            calledExpressionBase = nil
        } else {
            return nil
        }

        guard
            let argument = arguments.onlyElement,
            argument.label?.text == "contentMode",
            let memberValue = argument.expression.as(MemberAccessExprSyntax.self),
            memberValue.isSwiftUIContentModeConstant,
            ["fit", "fill"].contains(memberValue.declName.baseName.text)
        else {
            return nil
        }

        return LegacySwiftUIAspectRatioViolation(
            position: violationPosition,
            calledExpressionBase: calledExpressionBase,
            replacementFunctionName: memberValue.declName.baseName.text == "fit" ? "scaledToFit" : "scaledToFill"
        )
    }
}

private extension MemberAccessExprSyntax {
    var isSwiftUIContentModeConstant: Bool {
        base == nil || base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "ContentMode"
    }
}
