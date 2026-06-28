import SwiftSyntax

@SwiftSyntaxRule
struct ForceTryRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "force_try",
        name: "Force Try",
        description: "Force tries should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            """
            func a() throws {}
            do {
              try a()
            } catch {}
            """,
        ]),
        triggeringExamples: #examples([
            """
            func a() throws {}
            ↓try! a()
            """,
        ])
    )
}

private extension ForceTryRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TryExprSyntax) {
            if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
