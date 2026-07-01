import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct FallthroughRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "fallthrough",
        name: "Fallthrough",
        description: "Fallthrough should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            """
            switch foo {
            case .bar, .bar2, .bar3:
              something()
            }
            """,
        ]),
        triggeringExamples: #examples([
            """
            switch foo {
            case .bar:
              ↓fallthrough
            case .bar2:
              something()
            }
            """,
        ])
    )
}

private extension FallthroughRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FallThroughStmtSyntax) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
