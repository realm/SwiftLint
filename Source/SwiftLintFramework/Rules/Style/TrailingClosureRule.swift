import SwiftSyntax

public struct TrailingClosureRule: OptInRule, SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = TrailingClosureConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_closure",
        name: "Trailing Closure",
        description: "Trailing closure syntax should be used whenever possible.",
        kind: .style,
        nonTriggeringExamples: [
            Example("foo.map { $0 + 1 }\n"),
            Example("foo.bar()\n"),
            Example("foo.reduce(0) { $0 + 1 }\n"),
            Example("if let foo = bar.map({ $0 + 1 }) { }\n"),
            Example("foo.something(param1: { $0 }, param2: { $0 + 1 })\n"),
            Example("offsets.sorted { $0.offset < $1.offset }\n"),
            Example("foo.something({ return 1 }())"),
            Example("foo.something({ return $0 }(1))"),
            Example("foo.something(0, { return 1 }())"),
            Example("for x in list.filter({ $0.isValid }) {}"),
            Example("if list.allSatisfy({ $0.isValid }) {}"),
            Example("foo(param1: 1, param2: { _ in true }, param3: 0)")
        ],
        triggeringExamples: [
            Example("↓foo.map({ $0 + 1 })\n"),
            Example("↓foo.reduce(0, combine: { $0 + 1 })\n"),
            Example("↓offsets.sorted(by: { $0.offset < $1.offset })\n"),
            Example("↓foo.something(0, { $0 + 1 })\n")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(onlySingleMutedParameter: configuration.onlySingleMutedParameter)
    }
}

private extension TrailingClosureRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        private let onlySingleMutedParameter: Bool

        init(onlySingleMutedParameter: Bool) {
            self.onlySingleMutedParameter = onlySingleMutedParameter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.trailingClosure == nil,
                  node.leftParen != nil,
                  node.argumentList.containsSingleClosureArgument,
                  node.argumentList.lastArgumentIsClosure else {
                return
            }

            if onlySingleMutedParameter,
               (node.argumentList.count > 1 || node.argumentList.first?.label != nil) {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visit(_ node: ForInStmtSyntax) -> SyntaxVisitorContinueKind {
            walk(node.body)
            return .skipChildren
        }

        override func visit(_ node: ConditionElementSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}

private extension TupleExprElementListSyntax {
    var containsSingleClosureArgument: Bool {
        return filter { element in
            element.expression.is(ClosureExprSyntax.self)
        }.count == 1
    }

    var lastArgumentIsClosure: Bool {
        last?.expression.as(ClosureExprSyntax.self) != nil
    }
}
