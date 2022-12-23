import SwiftSyntax

struct NSLocalizedStringKeyRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "nslocalizedstring_key",
        name: "NSLocalizedString Key",
        description: "Static strings should be used as key/comment" +
            " in NSLocalizedString in order for genstrings to work",
        kind: .lint,
        nonTriggeringExamples: [
            Example("NSLocalizedString(\"key\", comment: \"\")"),
            Example("NSLocalizedString(\"key\" + \"2\", comment: \"\")"),
            Example("NSLocalizedString(\"key\", comment: \"comment\")"),
            Example("""
            NSLocalizedString("This is a multi-" +
                "line string", comment: "")
            """),
            Example("""
            let format = NSLocalizedString("%@, %@.", comment: "Accessibility label for a post in the post list." +
            " The parameters are the title, and date respectively." +
            " For example, \"Let it Go, 1 hour ago.\"")
            """)
        ],
        triggeringExamples: [
            Example("NSLocalizedString(↓method(), comment: \"\")"),
            Example("NSLocalizedString(↓\"key_\\(param)\", comment: \"\")"),
            Example("NSLocalizedString(\"key\", comment: ↓\"comment with \\(param)\")"),
            Example("NSLocalizedString(↓\"key_\\(param)\", comment: ↓method())")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NSLocalizedStringKeyRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text == "NSLocalizedString" else {
                return
            }

            if let keyArgument = node.argumentList.first(where: { $0.label == nil })?.expression,
               keyArgument.hasViolation {
                violations.append(keyArgument.positionAfterSkippingLeadingTrivia)
            }

            if let commentArgument = node.argumentList.first(where: { $0.label?.text == "comment" })?.expression,
               commentArgument.hasViolation {
                violations.append(commentArgument.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension ExprSyntax {
    var hasViolation: Bool {
        if let strExpr = self.as(StringLiteralExprSyntax.self) {
            return strExpr.segments.contains { segment in
                !segment.is(StringSegmentSyntax.self)
            }
        }

        if let sequenceExpr = self.as(SequenceExprSyntax.self) {
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
