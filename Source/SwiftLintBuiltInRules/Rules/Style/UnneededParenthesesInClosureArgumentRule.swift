import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct UnneededParenthesesInClosureArgumentRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unneeded_parentheses_in_closure_argument",
        name: "Unneeded Parentheses in Closure Argument",
        description: "Parentheses are not needed when declaring closure arguments",
        kind: .style,
        nonTriggeringExamples: [
            Example("let foo = { (bar: Int) in }"),
            Example("let foo = { bar, _  in }"),
            Example("let foo = { bar in }"),
            Example("let foo = { bar -> Bool in return true }"),
            Example("""
            DispatchQueue.main.async { () -> Void in
                doSomething()
            }
            """),
            Example("""
            registerFilter(name) { any, args throws -> Any? in
                doSomething(any, args)
            }
            """, excludeFromDocumentation: true),
        ],
        triggeringExamples: [
            Example("call(arg: { ↓(bar) in })"),
            Example("call(arg: { ↓(bar, _) in })"),
            Example("let foo = { ↓(bar) -> Bool in return true }"),
            Example("foo.map { ($0, $0) }.forEach { ↓(x, y) in }"),
            Example("foo.bar { [weak self] ↓(x, y) in }"),
            Example("""
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
            """),
            Example("""
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
            """),
            Example("""
            registerFilter(name) { ↓(any, args) throws -> Any? in
                doSomething(any, args)
            }
            """, excludeFromDocumentation: true),
        ],
        corrections: [
            Example("call(arg: { ↓(bar) in })"): Example("call(arg: { bar in })"),
            Example("call(arg: { ↓(bar, _) in })"): Example("call(arg: { bar, _ in })"),
            Example("call(arg: { ↓(bar, _)in })"): Example("call(arg: { bar, _ in })"),
            Example("let foo = { ↓(bar) -> Bool in return true }"):
                Example("let foo = { bar -> Bool in return true }"),
            Example("method { ↓(foo, bar) in }"): Example("method { foo, bar in }"),
            Example("foo.map { ($0, $0) }.forEach { ↓(x, y) in }"): Example("foo.map { ($0, $0) }.forEach { x, y in }"),
            Example("foo.bar { [weak self] ↓(x, y) in }"): Example("foo.bar { [weak self] x, y in }"),
        ]
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

            correctionPositions.append(clause.positionAfterSkippingLeadingTrivia)

            let paramList = ClosureShorthandParameterListSyntax(items).with(\.trailingTrivia, .spaces(1))
            return super.visit(node.with(\.parameterClause, .init(paramList)))
        }
    }
}
