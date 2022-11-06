import SwiftSyntax

struct MultipleClosuresWithTrailingClosureRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "multiple_closures_with_trailing_closure",
        name: "Multiple Closures with Trailing Closure",
        description: "Trailing closure syntax should not be used when passing more than one closure argument",
        kind: .style,
        nonTriggeringExamples: [
            Example("foo.map { $0 + 1 }\n"),
            Example("foo.reduce(0) { $0 + $1 }\n"),
            Example("if let foo = bar.map({ $0 + 1 }) {\n\n}\n"),
            Example("foo.something(param1: { $0 }, param2: { $0 + 1 })\n"),
            Example("""
            UIView.animate(withDuration: 1.0) {
                someView.alpha = 0.0
            }
            """),
            Example("foo.method { print(0) } arg2: { print(1) }"),
            Example("foo.methodWithParenArgs((0, 1), arg2: (0, 1, 2)) { $0 } arg4: { $0 }")
        ],
        triggeringExamples: [
            Example("foo.something(param1: { $0 }) ↓{ $0 + 1 }"),
            Example("""
            UIView.animate(withDuration: 1.0, animations: {
                someView.alpha = 0.0
            }) ↓{ _ in
                someView.removeFromSuperview()
            }
            """),
            Example("foo.multipleTrailing(arg1: { $0 }) { $0 } arg3: { $0 }"),
            Example("foo.methodWithParenArgs(param1: { $0 }, param2: (0, 1), (0, 1)) { $0 }")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension MultipleClosuresWithTrailingClosureRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let trailingClosure = node.trailingClosure,
                  node.hasTrailingClosureViolation else {
                return
            }

            violations.append(trailingClosure.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension FunctionCallExprSyntax {
    var hasTrailingClosureViolation: Bool {
        guard trailingClosure != nil else {
            return false
        }

        return argumentList.contains { elem in
            elem.expression.is(ClosureExprSyntax.self)
        }
    }
}
