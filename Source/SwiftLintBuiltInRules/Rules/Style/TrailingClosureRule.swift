import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct TrailingClosureRule: OptInRule {
    var configuration = TrailingClosureConfiguration()

    static let description = RuleDescription(
        identifier: "trailing_closure",
        name: "Trailing Closure",
        description: "Trailing closure syntax should be used whenever possible",
        kind: .style,
        nonTriggeringExamples: [
            Example("foo.map { $0 + 1 }"),
            Example("foo.bar()"),
            Example("foo.reduce(0) { $0 + 1 }"),
            Example("if let foo = bar.map({ $0 + 1 }) { }"),
            Example("foo.something(param1: { $0 }, param2: { $0 + 1 })"),
            Example("offsets.sorted { $0.offset < $1.offset }"),
            Example("foo.something({ return 1 }())"),
            Example("foo.something({ return $0 }(1))"),
            Example("foo.something(0, { return 1 }())"),
            Example("foo.something(0, { return 1 }())"),
            Example("for x in list.filter({ $0.isValid }) {}"),
            Example("if list.allSatisfy({ $0.isValid }) {}"),
            Example("foo(param1: 1, param2: { _ in true }, param3: 0)"),
            Example("foo(param1: 1, param2: { _ in true }) { $0 + 1 }")
        ],
        triggeringExamples: [
            Example("↓foo.map({ $0 + 1 })"),
            Example("↓foo.reduce(0, combine: { $0 + 1 })"),
            Example("↓offsets.sorted(by: { $0.offset < $1.offset })"),
            Example("↓foo.something(0, { $0 + 1 })")
        ]
    )
}

private extension TrailingClosureRule {
    class Visitor: ViolationsSyntaxVisitor<TrailingClosureConfiguration> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.trailingClosure == nil else { return }

            if configuration.onlySingleMutedParameter {
                guard node.containsOnlySingleMutedParameter, node.isNotNextToLeftBrace else { return }

                violations.append(node.positionAfterSkippingLeadingTrivia)
            } else {
                guard node.lastArgumentIsClosure, node.isNotNextToLeftBrace else { return }

                if node.shouldTrigger {
                    violations.append(node.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}

private extension SyntaxProtocol {
    var isNotNextToLeftBrace: Bool {
        nextToken(viewMode: .sourceAccurate)?.tokenKind != .leftBrace
    }
}

private extension FunctionCallExprSyntax {
    var lastArgumentIsClosure: Bool {
        arguments.last?.expression.is(ClosureExprSyntax.self) == true
    }

    var containsOnlySingleMutedParameter: Bool {
        arguments.count == 1
        && arguments.first?.expression.is(ClosureExprSyntax.self) == true
        && arguments.first?.label == nil
    }

    var shouldTrigger: Bool {
        // If at least last two arguments were ClosureExprSyntax, a violation should not be triggered.
        arguments.count <= 1
        || !arguments.dropFirst(arguments.count - 2).allSatisfy({ $0.expression.is(ClosureExprSyntax.self) })
    }
}
