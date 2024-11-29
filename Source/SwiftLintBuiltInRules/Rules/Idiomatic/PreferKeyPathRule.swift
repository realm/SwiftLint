import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct PreferKeyPathRule: OptInRule {
    var configuration = PreferKeyPathConfiguration()

    private static let extendedMode = ["restrict_to_standard_functions": false]

    static let description = RuleDescription(
        identifier: "prefer_key_path",
        name: "Prefer Key Path",
        description: "Use a key path argument instead of a closure with property access",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotTwo,
        nonTriggeringExamples: [
            Example("f {}"),
            Example("f { $0 }"),
            Example("f { $0.a }"),
            Example("let f = { $0.a }(b)"),
            Example("f {}", configuration: extendedMode),
            Example("f { $0 }", configuration: extendedMode),
            Example("f() { g() }", configuration: extendedMode),
            Example("f { a.b.c }", configuration: extendedMode),
            Example("f { a in a }", configuration: extendedMode),
            Example("f { a, b in a.b }", configuration: extendedMode),
            Example("f { (a, b) in a.b }", configuration: extendedMode),
            Example("f { $0.a } g: { $0.b }", configuration: extendedMode),
            Example("[1, 2, 3].reduce(1) { $0 + $1 }", configuration: extendedMode),
            Example("f.map(1) { $0.a }"),
            Example("f.filter({ $0.a }, x)"),
            Example("#Predicate { $0.a }"),
        ],
        triggeringExamples: [
            Example("f.map ↓{ $0.a }"),
            Example("f.filter ↓{ $0.a }"),
            Example("f.first ↓{ $0.a }"),
            Example("f.contains ↓{ $0.a }"),
            Example("f.contains(where: ↓{ $0.a })"),
            Example("f(↓{ $0.a })", configuration: extendedMode),
            Example("f(a: ↓{ $0.b })", configuration: extendedMode),
            Example("f(a: ↓{ a in a.b }, x)", configuration: extendedMode),
            Example("f.map ↓{ a in a.b.c }"),
            Example("f.allSatisfy ↓{ (a: A) in a.b }"),
            Example("f.first ↓{ (a b: A) in b.c }"),
            Example("f.contains ↓{ $0.0.a }"),
            Example("f.compactMap ↓{ $0.a.b.c.d }"),
            Example("f.flatMap ↓{ $0.a.b }"),
            Example("let f: (Int) -> Int = ↓{ $0.bigEndian }", configuration: extendedMode),
        ],
        corrections: [
            Example("f.map { $0.a }"):
                Example("f.map(\\.a)"),
            Example("""
                // begin
                f.map { $0.a } // end
                """):
                Example("""
                    // begin
                    f.map(\\.a) // end
                    """),
            Example("f.map({ $0.a })"):
                Example("f.map(\\.a)"),
            Example("f(a: { $0.a })", configuration: extendedMode):
                Example("f(a: \\.a)"),
            Example("f({ $0.a })", configuration: extendedMode):
                Example("f(\\.a)"),
            Example("let f = /* begin */ { $0.a } // end", configuration: extendedMode):
                Example("let f = /* begin */ \\.a // end"),
            Example("let f = { $0.a }(b)"):
                Example("let f = { $0.a }(b)"),
            Example("let f: (Int) -> Int = ↓{ $0.bigEndian }", configuration: extendedMode):
                Example("let f: (Int) -> Int = \\.bigEndian"),
            Example("f.partition ↓{ $0.a.b }"):
                Example("f.partition(by: \\.a.b)"),
            Example("f.contains ↓{ $0.a.b }"):
                Example("f.contains(where: \\.a.b)"),
            Example("f.first ↓{ element in element.a }"):
                Example("f.first(where: \\.a)"),
            Example("f.drop ↓{ element in element.a }"):
                Example("f.drop(while: \\.a)"),
            Example("f.compactMap ↓{ $0.a.b.c.d }"):
                Example("f.compactMap(\\.a.b.c.d)"),
        ]
    )
}

private extension PreferKeyPathRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureExprSyntax) {
            if node.isInvalid(restrictToStandardFunctions: configuration.restrictToStandardFunctions) {
                return
            }
            if node.onlyExprStmt?.accesses(identifier: node.onlyParameter) == true {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard node.additionalTrailingClosures.isEmpty,
                  let closure = node.trailingClosure,
                  !closure.isInvalid(restrictToStandardFunctions: configuration.restrictToStandardFunctions),
                  let expr = closure.onlyExprStmt,
                  expr.accesses(identifier: closure.onlyParameter) == true,
                  let declName = expr.as(MemberAccessExprSyntax.self),
                  let calleeName = node.calleeName else {
                return super.visit(node)
            }
            correctionPositions.append(closure.positionAfterSkippingLeadingTrivia)
            var node = node.with(\.calledExpression, node.calledExpression.with(\.trailingTrivia, []))
            if node.leftParen == nil {
                node = node.with(\.leftParen, .leftParenToken())
            }
            let newArg = LabeledExprSyntax(
                label: argumentLabelByStandardFunction[calleeName, default: nil],
                expression: declName.asKeyPath
            )
            node = node.with(\.arguments, [newArg]
            )
            if node.rightParen == nil {
                node = node.with(\.rightParen, .rightParenToken())
            }
            node = node
                .with(\.trailingClosure, nil)
                .with(\.trailingTrivia, node.trailingTrivia)
            return super.visit(node)
        }

        override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
            if node.isInvalid(restrictToStandardFunctions: configuration.restrictToStandardFunctions) {
                return super.visit(node)
            }
            if let expr = node.onlyExprStmt,
               expr.accesses(identifier: node.onlyParameter) == true,
               let declName = expr.as(MemberAccessExprSyntax.self) {
                correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
                let node = declName.asKeyPath
                    .with(\.leadingTrivia, node.leadingTrivia)
                    .with(\.trailingTrivia, node.trailingTrivia)
                return super.visit(node)
            }
            return super.visit(node)
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

    var onlyExprStmt: ExprSyntax? {
        if case let .expr(expr) = statements.onlyElement?.item {
            return expr
        }
        return nil
    }

    func isInvalid(restrictToStandardFunctions: Bool) -> Bool {
        guard keyPathInParent != \FunctionCallExprSyntax.calledExpression,
              let parentKind = parent?.kind,
              ![.macroExpansionExpr, .multipleTrailingClosureElement].contains(parentKind) else {
            return true
        }
        if let call = parent?.as(LabeledExprSyntax.self)?.parent?.parent?.as(FunctionCallExprSyntax.self) {
            // Closure is function argument.
            return restrictToStandardFunctions && !call.isStandardFunction
        }
        return parent?.as(FunctionCallExprSyntax.self)?.isStandardFunction == false
    }
}

private let argumentLabelByStandardFunction: [String: String?] = [
    "allSatisfy": nil,
    "contains": "where",
    "compactMap": nil,
    "drop": "while",
    "filter": nil,
    "first": "where",
    "flatMap": nil,
    "map": nil,
    "partition": "by",
    "prefix": "while",
]

private extension FunctionCallExprSyntax {
    var isStandardFunction: Bool {
        if let calleeName, argumentLabelByStandardFunction.keys.contains(calleeName) {
            return arguments.count + (trailingClosure == nil ? 0 : 1) == 1
        }
        return false
    }

    var calleeName: String? {
        (calledExpression.as(DeclReferenceExprSyntax.self)
            ?? calledExpression.as(MemberAccessExprSyntax.self)?.declName)?.baseName.text
    }
}

private extension MemberAccessExprSyntax {
    var asKeyPath: ExprSyntax {
        var this = base
        var elements = [declName]
        while this?.is(DeclReferenceExprSyntax.self) != true {
            if let memberAccess = this?.as(MemberAccessExprSyntax.self) {
                elements.append(memberAccess.declName)
                this = memberAccess.base
            }
        }
        return "\\.\(raw: elements.reversed().map(\.baseName.text).joined(separator: "."))" as ExprSyntax
    }
}
