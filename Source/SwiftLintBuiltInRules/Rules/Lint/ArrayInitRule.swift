import SwiftSyntax

struct ArrayInitRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "array_init",
        name: "Array Init",
        description: "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array",
        kind: .lint,
        nonTriggeringExamples: [
            Example("Array(foo)"),
            Example("foo.map { $0.0 }"),
            Example("foo.map { $1 }"),
            Example("foo.map { $0() }"),
            Example("foo.map { ((), $0) }"),
            Example("foo.map { $0! }"),
            Example("foo.map { $0! /* force unwrap */ }"),
            Example("foo.something { RouteMapper.map($0) }"),
            Example("foo.map { !$0 }"),
            Example("foo.map { /* a comment */ !$0 }")
        ],
        triggeringExamples: [
            Example("foo.↓map({ $0 })"),
            Example("foo.↓map { $0 }"),
            Example("foo.↓map { return $0 }"),
            Example("""
                foo.↓map { elem in
                    elem
                }
            """),
            Example("""
                foo.↓map { elem in
                    return elem
                }
            """),
            Example("""
                foo.↓map { (elem: String) in
                    elem
                }
            """),
            Example("""
                foo.↓map { elem -> String in
                    elem
                }
            """),
            Example("foo.↓map { $0 /* a comment */ }"),
            Example("foo.↓map { /* a comment */ $0 }")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

extension ArrayInitRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
                  memberAccess.name.text == "map",
                  let (closureParam, closureStatement) = node.singleClosure(),
                  closureStatement.returnsInput(closureParam)
            else {
                return
            }

            violations.append(memberAccess.name.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension FunctionCallExprSyntax {
    func singleClosure() -> (String?, CodeBlockItemSyntax)? {
        let closure: ClosureExprSyntax
        if let expression = argumentList.onlyElement?.expression.as(ClosureExprSyntax.self) {
            closure = expression
        } else if argumentList.isEmpty, let expression = trailingClosure {
            closure = expression
        } else {
            return nil
        }

        if let closureStatement = closure.statements.onlyElement {
            return (closure.signature?.singleInputParamText(), closureStatement)
        } else {
            return nil
        }
    }
}

private extension CodeBlockItemSyntax {
    func returnsInput(_ closureParam: String?) -> Bool {
        let expectedReturnIdentifier = closureParam ?? "$0"
        let identifier = item.as(IdentifierExprSyntax.self) ??
            item.as(ReturnStmtSyntax.self)?.expression?.as(IdentifierExprSyntax.self)
        return identifier?.identifier.text == expectedReturnIdentifier
    }
}

private extension ClosureSignatureSyntax {
    func singleInputParamText() -> String? {
        if let list = input?.as(ClosureParamListSyntax.self), list.count == 1 {
            return list.onlyElement?.name.text
        } else if let clause = input?.as(ClosureParameterClauseSyntax.self), clause.parameterList.count == 1,
                  clause.parameterList.first?.secondName == nil {
            return clause.parameterList.first?.firstName.text
        } else {
            return nil
        }
    }
}
