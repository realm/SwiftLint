import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct UnneededParenthesesInClosureArgumentRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unneeded_parentheses_in_closure_argument",
        name: "Unneeded Parentheses in Closure Argument",
        description: "Parentheses are not needed when declaring closure arguments",
        kind: .style,
        nonTriggeringExamples: #examples([
            "let foo = { (bar: Int) in }",
            "let foo = { bar, _  in }",
            "let foo = { bar in }",
            "let foo = { bar -> Bool in return true }",
            """
            DispatchQueue.main.async { () -> Void in
                doSomething()
            }
            """,
            """
            registerFilter(name) { any, args throws -> Any? in
                doSomething(any, args)
            }
            """.excludeFromDocumentation(),
        ]),
        triggeringExamples: #examples([
            "call(arg: { ↓(bar) in })",
            "call(arg: { ↓(bar, _) in })",
            "let foo = { ↓(bar) -> Bool in return true }",
            "foo.map { ($0, $0) }.forEach { ↓(x, y) in }",
            "foo.bar { [weak self] ↓(x, y) in }",
            """
            [].first { ↓(temp) in
                [].first { ↓(temp) in
                    [].first { ↓(temp) in
                        _ = temp
                        return false
                    }
                    return false
                }
                return false
            }
            """,
            """
            [].first { temp in
                [].first { ↓(temp) in
                    [].first { ↓(temp) in
                        _ = temp
                        return false
                    }
                    return false
                }
                return false
            }
            """,
            """
            registerFilter(name) { ↓(any, args) throws -> Any? in
                doSomething(any, args)
            }
            """.excludeFromDocumentation(),
        ]),
        corrections: #corrections([
            "call(arg: { ↓(bar) in })": "call(arg: { bar in })",
            "call(arg: { ↓(bar, _) in })": "call(arg: { bar, _ in })",
            "call(arg: { ↓(bar, _)in })": "call(arg: { bar, _ in })",
            "let foo = { ↓(bar) -> Bool in return true }":
                "let foo = { bar -> Bool in return true }",
            "method { ↓(foo, bar) in }": "method { foo, bar in }",
            "foo.map { ($0, $0) }.forEach { ↓(x, y) in }": "foo.map { ($0, $0) }.forEach { x, y in }",
            "foo.bar { [weak self] ↓(x, y) in }": "foo.bar { [weak self] x, y in }",
        ])
    )
}

private extension UnneededParenthesesInClosureArgumentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureSignatureSyntax) {
            guard let clause = node.parameterClause?.as(ClosureParameterClauseSyntax.self),
                  clause.parameters.isNotEmpty,
                  clause.parameters.allSatisfy({ $0.type == nil }) else {
                return
            }

            violations.append(clause.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
            guard let clause = node.parameterClause?.as(ClosureParameterClauseSyntax.self),
                  clause.parameters.isNotEmpty,
                  clause.parameters.allSatisfy({ $0.type == nil }) else {
                return super.visit(node)
            }

            let items = clause.parameters.enumerated().compactMap { idx, param -> ClosureShorthandParameterSyntax? in
                let name = param.firstName
                let isLast = idx == clause.parameters.count - 1
                return ClosureShorthandParameterSyntax(
                    name: name,
                    trailingComma: isLast ? nil : .commaToken(trailingTrivia: Trivia(pieces: [.spaces(1)]))
                )
            }

            numberOfCorrections += 1
            let paramList = ClosureShorthandParameterListSyntax(items).with(\.trailingTrivia, .spaces(1))
            return super.visit(node.with(\.parameterClause, .init(paramList)))
        }
    }
}
