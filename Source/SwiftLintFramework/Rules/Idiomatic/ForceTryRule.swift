import SwiftSyntax

struct ForceTryRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    static let description = RuleDescription(
        identifier: "force_try",
        name: "Force Try",
        description: "Force tries should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            func a() throws {}
            do {
              try a()
            } catch {}
            """)
        ],
        triggeringExamples: [
            Example("""
            func a() throws {}
            ↓try! a()
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ForceTryRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: TryExprSyntax) {
            if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
