import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct PreferKeyPathRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description = RuleDescription(
        identifier: "prefer_key_path",
        name: "Prefer Key Path",
        description: "Use a key path argument instead of a closure with property access",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotTwo,
        nonTriggeringExamples: [
            Example("f {}"),
            Example("f { $0 }"),
            Example("f() { g() }"),
            Example("f { a.b.c }"),
            Example("f { a in a }"),
            Example("f { a, b in a.b }"),
            Example("f { (a, b) in a.b }"),
        ],
        triggeringExamples: [
            Example("f ↓{ $0.a }"),
            Example("f ↓{ a in a.b }"),
            Example("f ↓{ a in a.b.c }"),
            Example("f ↓{ (a: A) in a.b }"),
            Example("f ↓{ (a b: A) in b.c }"),
            Example("f ↓{ $0.0.a }"),
            Example("f(a: ↓{ $0.b })"),
            Example("f { 1 } a: ↓{ $0.b }"),
            Example("let f: (Int) -> Int = ↓{ $0.bigEndian }"),
        ]
    )
}

private extension PreferKeyPathRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureExprSyntax) {
            if case let .expr(expr) = node.statements.onlyElement?.item,
               expr.accesses(identifier: node.onlyParameter) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension ExprSyntax {
    func accesses(identifier: String?) -> Bool {
        if let base = `as`(MemberAccessExprSyntax.self)?.base {
            if let declRef = base.as(DeclReferenceExprSyntax.self) {
                return declRef.baseName.text == identifier ?? "$0"
            }
            return base.accesses(identifier: identifier)
        }
        return false
    }
}

private extension ClosureExprSyntax {
    var onlyParameter: String? {
        switch signature?.parameterClause {
        case let .simpleInput(params):
            return params.onlyElement?.name.text
        case let .parameterClause(params):
            let param = params.parameters.onlyElement
            return param?.secondName?.text ?? param?.firstName.text
        case nil: return nil
        }
    }
}
