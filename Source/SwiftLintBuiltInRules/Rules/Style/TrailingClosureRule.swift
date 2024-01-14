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
            Example("for x in list.filter({ $0.isValid }) {}"),
            Example("if list.allSatisfy({ $0.isValid }) {}"),
            Example("foo(param1: 1, param2: { _ in true }, param3: 0)"),
            Example("foo(param1: 1, param2: { _ in true }) { $0 + 1 }"),
            Example("foo(param1: { _ in false }, param2: { _ in true })"),
            Example("foo(param1: { _ in false }, param2: { _ in true }, param3: { _ in false })"),
            Example("""
            if f({ true }), g({ true }) {
                print("Hello")
            }
            """),
            Example("""
            for i in h({ [1,2,3] }) {
                print(i)
            }
            """)
        ],
        triggeringExamples: [
            Example("↓foo.map({ $0 + 1 })"),
            Example("↓foo.reduce(0, combine: { $0 + 1 })"),
            Example("↓offsets.sorted(by: { $0.offset < $1.offset })"),
            Example("↓foo.something(0, { $0 + 1 })"),
            Example("↓foo.something(param1: { _ in true }, param2: 0, param3: { _ in false })"),
            Example("""
            for n in list {
                ↓n.forEach({ print($0) })
            }
            """, excludeFromDocumentation: true)
        ]
    )
}

private extension TrailingClosureRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.trailingClosure == nil else { return }

            if configuration.onlySingleMutedParameter {
                guard node.containsOnlySingleMutedParameter else { return }

                violations.append(node.positionAfterSkippingLeadingTrivia)
            } else {
                if node.shouldTrigger {
                    violations.append(node.positionAfterSkippingLeadingTrivia)
                }
            }
        }

        override func visit(_ node: ConditionElementListSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
            walk(node.body)
            return .skipChildren
        }
    }
}

private extension FunctionCallExprSyntax {
    var containsOnlySingleMutedParameter: Bool {
        arguments.onlyElement?.isMutedClosure == true
    }

    var shouldTrigger: Bool {
        arguments.last?.expression.is(ClosureExprSyntax.self) == true
        // If at least last two arguments were ClosureExprSyntax, a violation should not be triggered.
        && (arguments.count <= 1
        || !arguments.dropFirst(arguments.count - 2).allSatisfy({ $0.expression.is(ClosureExprSyntax.self) }))
    }
}

private extension LabeledExprSyntax {
    var isMutedClosure: Bool {
        label == nil && expression.is(ClosureExprSyntax.self)
    }
}
