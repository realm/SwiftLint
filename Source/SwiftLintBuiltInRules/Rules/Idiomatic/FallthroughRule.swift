import SwiftSyntax

@SwiftSyntaxRule
struct FallthroughRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "fallthrough",
        name: "Fallthrough",
        description: "Fallthrough should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            switch foo {
            case .bar, .bar2, .bar3:
              something()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            switch foo {
            case .bar:
              ↓fallthrough
            case .bar2:
              something()
            }
            """)
        ]
    )
}

private extension FallthroughRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FallThroughStmtSyntax) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
