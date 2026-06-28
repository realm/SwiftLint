import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct NSLocalizedStringKeyRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "nslocalizedstring_key",
        name: "NSLocalizedString Key",
        description: "Static strings should be used as key/comment" +
            " in NSLocalizedString in order for genstrings to work",
        kind: .lint,
        nonTriggeringExamples: #examples([
            "NSLocalizedString(\"key\", comment: \"\")",
            "NSLocalizedString(\"key\" + \"2\", comment: \"\")",
            "NSLocalizedString(\"key\", comment: \"comment\")",
            """
            NSLocalizedString("This is a multi-" +
                "line string", comment: "")
            """,
            """
            let format = NSLocalizedString("%@, %@.", comment: "Accessibility label for a post in the post list." +
            " The parameters are the title, and date respectively." +
            " For example, \"Let it Go, 1 hour ago.\"")
            """,
        ]),
        triggeringExamples: #examples([
            "NSLocalizedString(↓method(), comment: \"\")",
            "NSLocalizedString(↓\"key_\\(param)\", comment: \"\")",
            "NSLocalizedString(\"key\", comment: ↓\"comment with \\(param)\")",
            "NSLocalizedString(↓\"key_\\(param)\", comment: ↓method())",
        ])
    )
}

private extension NSLocalizedStringKeyRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "NSLocalizedString" else {
                return
            }

            if let keyArgument = node.arguments.first(where: { $0.label == nil })?.expression,
               keyArgument.hasViolation {
                violations.append(keyArgument.positionAfterSkippingLeadingTrivia)
            }

            if let commentArgument = node.arguments.first(where: { $0.label?.text == "comment" })?.expression,
               commentArgument.hasViolation {
                violations.append(commentArgument.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension ExprSyntax {
    var hasViolation: Bool {
        if let strExpr = `as`(StringLiteralExprSyntax.self) {
            return strExpr.segments.contains { segment in
                !segment.is(StringSegmentSyntax.self)
            }
        }

        if let sequenceExpr = `as`(SequenceExprSyntax.self) {
            return sequenceExpr.elements.contains { expr in
                if expr.is(BinaryOperatorExprSyntax.self) {
                    return false
                }

                return expr.hasViolation
            }
        }

        return true
    }
}
