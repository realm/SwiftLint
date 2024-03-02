import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
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
            Example("foo.map(↓{ $0 + 1 })"),
            Example("foo.reduce(0, combine: ↓{ $0 + 1 })"),
            Example("offsets.sorted(by: ↓{ $0.offset < $1.offset })"),
            Example("foo.something(0, ↓{ $0 + 1 })"),
            Example("foo.something(param1: { _ in true }, param2: 0, param3: ↓{ _ in false })"),
            Example("""
            for n in list {
                n.forEach(↓{ print($0) })
            }
            """, excludeFromDocumentation: true)
        ],
        corrections: [
            Example("foo.map(↓{ $0 + 1 })"):
                Example("foo.map { $0 + 1 }"),
            Example("foo.reduce(0, combine: ↓{ $0 + 1 })"):
                Example("foo.reduce(0) { $0 + 1 }"),
            Example("offsets.sorted(by: ↓{ $0.offset < $1.offset })"):
                Example("offsets.sorted { $0.offset < $1.offset }"),
            Example("foo.something(0, ↓{ $0 + 1 })"):
                Example("foo.something(0) { $0 + 1 }"),
            Example("foo.something(param1: { _ in true }, param2: 0, param3: ↓{ _ in false })"):
                Example("foo.something(param1: { _ in true }, param2: 0) { _ in false }"),
            Example("""
                for n in list {
                    n.forEach(↓{ print($0) })
                }
                """): Example("""
                    for n in list {
                        n.forEach { print($0) }
                    }
                    """),
            Example("""
                f(a: 1,
                b: 2,
                c: { 3 })
                """): Example("""
                    f(a: 1,
                    b: 2) { 3 }
                    """),
            Example("""
                f(a: 1, // comment
                b: 2, /* comment */ c: { 3 })
                """): Example("""
                    f(a: 1, // comment
                    b: 2) /* comment */ { 3 }
                    """),
            Example("""
                f(a: 2, c: /* comment */ { 3 } /* comment */)
                """): Example("""
                    f(a: 2) /* comment */ { 3 } /* comment */
                    """)
        ]
    )
}

private extension TrailingClosureRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.trailingClosure == nil else { return }

            if configuration.onlySingleMutedParameter {
                if let param = node.singleMutedClosureParameter {
                    violations.append(param.positionAfterSkippingLeadingTrivia)
                }
            } else if let param = node.lastDistinctClosureParameter {
                violations.append(param.positionAfterSkippingLeadingTrivia)
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

private extension TrailingClosureRule {
    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard node.trailingClosure == nil else { return super.visit(node) }

            if configuration.onlySingleMutedParameter {
                if let param = node.singleMutedClosureParameter,
                let converted = node.convertToTrailingClosure() {
                     correctionPositions.append(param.positionAfterSkippingLeadingTrivia)
                    return ExprSyntax(converted)
                }
            } else if let param = node.lastDistinctClosureParameter,
                      let converted = node.convertToTrailingClosure() {
                correctionPositions.append(param.positionAfterSkippingLeadingTrivia)
                return ExprSyntax(converted)
            }
            return super.visit(node)
        }

        override func visit(_ node: ConditionElementListSyntax) -> ConditionElementListSyntax {
            node
        }

        override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
            if let body = rewrite(node.body).as(CodeBlockSyntax.self) {
                StmtSyntax(node.with(\.body, body))
            } else {
                StmtSyntax(node)
            }
        }
    }
}

private extension FunctionCallExprSyntax {
    var singleMutedClosureParameter: ClosureExprSyntax? {
        if let onlyArgument = arguments.onlyElement, onlyArgument.label == nil {
            return onlyArgument.expression.as(ClosureExprSyntax.self)
        }
        return nil
    }

    var lastDistinctClosureParameter: ClosureExprSyntax? {
        // If at least the last two (connected) arguments were ClosureExprSyntax, a violation should not be triggered.
        guard arguments.count > 1, arguments.dropFirst(arguments.count - 2).allSatisfy(\.isClosureExpr) else {
            return arguments.last?.expression.as(ClosureExprSyntax.self)
        }
        return nil
    }

    func dropLastArgument() -> Self {
        let arguments = LabeledExprListSyntax(arguments.dropLast())

        return self
            .with(\.arguments, arguments.dropLastTrailingComma())
            .dropParensIfEmpty()
    }

    func dropParensIfEmpty() -> Self {
        if arguments.isEmpty {
            self
                .with(\.rightParen, nil)
                .with(\.leftParen, nil)
        } else {
            self
        }
    }

    func convertToTrailingClosure() -> Self? {
        guard trailingClosure == nil, let lastDistinctClosureParameter else { return nil }
        let leadingTrivia = lastTriviasInArguments?
            .removingLeadingNewlinesIfExists()
            .appendingSpaceIfNoTrailingSpace() ?? []

        return dropLastArgument()
            .with(\.trailingClosure, lastDistinctClosureParameter.with(\.leadingTrivia, leadingTrivia))
            .with(\.calledExpression.trailingTrivia, [])
    }

    var lastTriviasInArguments: Trivia? {
        guard let lastArgument = arguments.last,
              let previous = lastArgument.previousToken(viewMode: .sourceAccurate)?.trailingTrivia else { return nil }

        return previous
            .merging(lastArgument.leadingTrivia)
            .merging(triviaOf: lastArgument.label)
            .merging(triviaOf: lastArgument.colon)
    }
}

private extension LabeledExprSyntax {
    var isClosureExpr: Bool {
        expression.is(ClosureExprSyntax.self)
    }
}

private extension LabeledExprListSyntax {
    func dropLastTrailingComma() -> Self {
        guard let last else { return [] }

        if last.trailingComma == nil {
            return self
        } else {
            return LabeledExprListSyntax(dropLast()) + CollectionOfOne(last.with(\.trailingComma, nil))
        }
    }
}

private extension Trivia {
    var endsWithSpace: Bool {
        if let last = pieces.last, case .spaces = last {
            return true
        } else {
            return false
        }
    }

    var startsWithNewline: Bool {
        first?.isNewline == true
    }

    func appendingSpaceIfNoTrailingSpace() -> Self {
        if endsWithSpace {
            self
        } else {
            merging(.space)
        }
    }

    func removingLeadingNewlinesIfExists() -> Self {
        if startsWithNewline {
            Trivia(pieces: pieces.drop(while: { $0.isNewline }))
        } else {
            self
        }
    }
}
