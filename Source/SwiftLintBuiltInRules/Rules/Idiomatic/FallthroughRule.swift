import SwiftSyntax

struct FallthroughRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension FallthroughRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FallthroughStmtSyntax) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
