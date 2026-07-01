import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct TrailingClosureRule: Rule {
    var configuration = TrailingClosureConfiguration()

    private static let onlySingleMutedConfig = ["only_single_muted_parameter": true]

    static let description = RuleDescription(
        identifier: "trailing_closure",
        name: "Trailing Closure",
        description: "Trailing closure syntax should be used whenever possible",
        kind: .style,
        nonTriggeringExamples: #examples([
            "foo.map { $0 + 1 }",
            "foo.bar()",
            "foo.reduce(0) { $0 + 1 }",
            "if let foo = bar.map({ $0 + 1 }) { }",
            "foo.something(param1: { $0 }, param2: { $0 + 1 })",
            "offsets.sorted { $0.offset < $1.offset }",
            "foo.something({ return 1 }())",
            "foo.something({ return $0 }(1))",
            "foo.something(0, { return 1 }())",
            "for x in list.filter({ $0.isValid }) {}",
            "if list.allSatisfy({ $0.isValid }) {}",
            "foo(param1: 1, param2: { _ in true }, param3: 0)",
            "foo(param1: 1, param2: { _ in true }) { $0 + 1 }",
            "foo(param1: { _ in false }, param2: { _ in true })",
            "foo(param1: { _ in false }, param2: { _ in true }, param3: { _ in false })",
            """
            if f({ true }), g({ true }) {
                print("Hello")
            }
            """,
            """
            for i in h({ [1,2,3] }) {
                print(i)
            }
            """,
            "foo.reduce(0, combine: { $0 + 1 })".configuration(onlySingleMutedConfig),
            "offsets.sorted(by: { $0.offset < $1.offset })".configuration(onlySingleMutedConfig),
            "foo.something(0, { $0 + 1 })".configuration(onlySingleMutedConfig),
        ]),
        triggeringExamples: #examples([
            "foo.map(↓{ $0 + 1 })",
            "foo.reduce(0, combine: ↓{ $0 + 1 })",
            "offsets.sorted(by: ↓{ $0.offset < $1.offset })",
            "foo.something(0, ↓{ $0 + 1 })",
            "foo.something(param1: { _ in true }, param2: 0, param3: ↓{ _ in false })",
            """
            for n in list {
                n.forEach(↓{ print($0) })
            }
            """.excludeFromDocumentation(),
            "foo.map(↓{ $0 + 1 })".configuration(onlySingleMutedConfig),
        ]),
        corrections: #corrections([
            "foo.map(↓{ $0 + 1 })":
                "foo.map { $0 + 1 }",
            "foo.reduce(0, combine: ↓{ $0 + 1 })":
                "foo.reduce(0) { $0 + 1 }",
            "offsets.sorted(by: ↓{ $0.offset < $1.offset })":
                "offsets.sorted { $0.offset < $1.offset }",
            "foo.something(0, ↓{ $0 + 1 })":
                "foo.something(0) { $0 + 1 }",
            "foo.something(param1: { _ in true }, param2: 0, param3: ↓{ _ in false })":
                "foo.something(param1: { _ in true }, param2: 0) { _ in false }",
            "f(a: ↓{ g(b: ↓{ 1 }) })":
                "f { g { 1 }}",
            """
                for n in list {
                    n.forEach(↓{ print($0) })
                }
                """: """
                    for n in list {
                        n.forEach { print($0) }
                    }
                    """,
            """
                f(a: 1,
                b: 2,
                c: { 3 })
                """: """
                    f(a: 1,
                    b: 2) { 3 }
                    """,
            "foo.map(↓{ $0 + 1 })".configuration(onlySingleMutedConfig):
                "foo.map { $0 + 1 }".configuration(onlySingleMutedConfig),
            "f(↓{ g(↓{ 1 }) })".configuration(onlySingleMutedConfig):
                "f { g { 1 }}".configuration(onlySingleMutedConfig),
            """
                for n in list {
                    n.forEach(↓{ print($0) })
                }
                """.configuration(onlySingleMutedConfig): """
                    for n in list {
                        n.forEach { print($0) }
                    }
                    """,
            """
                f(a: 1, // comment
                b: 2, /* comment */ c: { 3 })
                """: """
                    f(a: 1, // comment
                    b: 2) /* comment */ { 3 }
                    """,
            """
                f(a: 2, c: /* comment */ { 3 } /* comment */)
                """: """
                    f(a: 2) /* comment */ { 3 } /* comment */
                    """,
            """
                f(a: 2, /* comment */ c /* comment */ : /* comment */ { 3 } /* comment */)
                """: """
                    f(a: 2) /* comment */ { 3 } /* comment */
                    """,
            """
                f(a: 2, /* comment1 */ c /* comment2 */ : /* comment3 */ { 3 } /* comment4 */)
                """: """
                    f(a: 2) /* comment1 */ /* comment2 */ /* comment3 */ { 3 } /* comment4 */
                    """,
            """
                let dataSource = RxTableViewSectionedReloadDataSource(
                    configureCell: { cell in // swiftlint:disable:this trailing_closure
                        return cell
                    }
                )
                """: """
                let dataSource = RxTableViewSectionedReloadDataSource(
                    configureCell: { cell in // swiftlint:disable:this trailing_closure
                        return cell
                    }
                )
                """,
        ])
    )
}

private extension TrailingClosureRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.trailingClosure == nil else {
                return
            }

            if configuration.onlySingleMutedParameter {
                if let param = node.singleMutedClosureParameter {
                    violations.append(param.positionAfterSkippingLeadingTrivia)
                }
            } else if let param = node.lastDistinctClosureParameter {
                violations.append(param.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_: ConditionElementListSyntax) -> SyntaxVisitorContinueKind {
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
            guard node.trailingClosure == nil else {
                return super.visit(node)
            }

            if configuration.onlySingleMutedParameter {
                if let param = node.singleMutedClosureParameter,
                   !isDisabled(atStartPositionOf: param),
                   let converted = node.convertToTrailingClosure() {
                    numberOfCorrections += 1
                    return super.visit(converted)
                }
            } else if let param = node.lastDistinctClosureParameter,
                      !isDisabled(atStartPositionOf: param),
                      let converted = node.convertToTrailingClosure() {
                numberOfCorrections += 1
                return super.visit(converted)
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
        with(\.arguments, LabeledExprListSyntax(arguments.dropLast()).dropLastTrailingComma())
            .dropParensIfEmpty()
    }

    func dropParensIfEmpty() -> Self {
        if arguments.isEmpty {
            with(\.rightParen, nil)
                .with(\.leftParen, nil)
        } else {
            self
        }
    }

    func convertToTrailingClosure() -> Self? {
        guard let lastDistinctClosureParameter else {
            return nil
        }
        let leadingTrivia = lastTriviaInArguments?
            .removingLeadingNewlines()
            .appendingMissingSpace() ?? []

        return dropLastArgument()
            .with(\.trailingClosure, lastDistinctClosureParameter.with(\.leadingTrivia, leadingTrivia))
            .with(\.calledExpression.trailingTrivia, [])
    }

    var lastTriviaInArguments: Trivia? {
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
        }
        return LabeledExprListSyntax(dropLast()) + CollectionOfOne(last.with(\.trailingComma, nil))
    }
}

private extension Trivia {
    var endsWithSpace: Bool {
        if case .spaces = pieces.last {
            return true
        }
        return false
    }

    var startsWithNewline: Bool {
        first?.isNewline == true
    }

    func appendingMissingSpace() -> Self {
        if endsWithSpace {
            self
        } else {
            merging(.space)
        }
    }

    func removingLeadingNewlines() -> Self {
        if startsWithNewline {
            Trivia(pieces: pieces.drop(while: \.isNewline))
        } else {
            self
        }
    }
}
