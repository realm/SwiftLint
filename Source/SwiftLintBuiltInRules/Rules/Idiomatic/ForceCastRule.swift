import SwiftSyntax

@SwiftSyntaxRule
struct ForceCastRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "force_cast",
        name: "Force Cast",
        description: "Force casts should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("NSNumber() as? Int")
        ],
        triggeringExamples: [ Example("NSNumber() ↓as! Int") ]
    )
}

private extension ForceCastRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: AsExprSyntax) {
            if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
                violations.append(node.asKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: UnresolvedAsExprSyntax) {
            if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
                violations.append(node.asKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
