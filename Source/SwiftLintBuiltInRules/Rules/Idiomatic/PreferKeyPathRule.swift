import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct PreferKeyPathRule: OptInRule {
    var configuration = PreferKeyPathConfiguration()

    private static let checkAllClosures = ["restrict_to_standard_functions": false]

    static var description = RuleDescription(
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
            Example("f {}", configuration: checkAllClosures),
            Example("f { $0 }", configuration: checkAllClosures),
            Example("f() { g() }", configuration: checkAllClosures),
            Example("f { a.b.c }", configuration: checkAllClosures),
            Example("f { a in a }", configuration: checkAllClosures),
            Example("f { a, b in a.b }", configuration: checkAllClosures),
            Example("f { (a, b) in a.b }", configuration: checkAllClosures),
            Example("f { $0.a } g: { $0.b }", configuration: checkAllClosures),
        ],
        triggeringExamples: [
            Example("f.map ↓{ $0.a }"),
            Example("f.filter ↓{ $0.a }"),
            Example("f ↓{ $0.a }", configuration: checkAllClosures),
            Example("f ↓{ a in a.b }", configuration: checkAllClosures),
            Example("f ↓{ a in a.b.c }", configuration: checkAllClosures),
            Example("f ↓{ (a: A) in a.b }", configuration: checkAllClosures),
            Example("f ↓{ (a b: A) in b.c }", configuration: checkAllClosures),
            Example("f ↓{ $0.0.a }", configuration: checkAllClosures),
            Example("f(a: ↓{ $0.b })", configuration: checkAllClosures),
            Example("f ↓{ $0.a.b }", configuration: checkAllClosures),
            Example("let f: (Int) -> Int = ↓{ $0.bigEndian }", configuration: checkAllClosures),
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
            Example("f { $0.a }", configuration: checkAllClosures):
                Example("f(\\.a)"),
            Example("f() { $0.a }", configuration: checkAllClosures):
                Example("f(\\.a)"),
            Example("let f = /* begin */ { $0.a } // end", configuration: checkAllClosures):
                Example("let f = /* begin */ \\.a // end"),
            Example("let f = { $0.a }(b)"):
                Example("let f = { $0.a }(b)"),
            Example("let f: (Int) -> Int = ↓{ $0.bigEndian }", configuration: checkAllClosures):
                Example("let f: (Int) -> Int = \\.bigEndian"),
            Example("f ↓{ $0.a.b }", configuration: checkAllClosures):
                Example("f(\\.a.b)"),
        ]
    )
}

private extension PreferKeyPathRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureExprSyntax) {
            if node.isInvalid(standardFunctionsOnly: configuration.restrictToStandardFunctions) {
                return
            }
            if node.onlyExprStmt?.accesses(identifier: node.onlyParameter) == true {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            if configuration.restrictToStandardFunctions, !node.isStandardFunction {
                return super.visit(node)
            }
            guard node.additionalTrailingClosures.isEmpty,
                  let closure = node.trailingClosure,
                  let expr = closure.onlyExprStmt,
                  expr.accesses(identifier: closure.onlyParameter) == true,
                  let declName = expr.as(MemberAccessExprSyntax.self) else {
                return super.visit(node)
            }
            correctionPositions.append(closure.positionAfterSkippingLeadingTrivia)
            var node = node.with(\.calledExpression, node.calledExpression.with(\.trailingTrivia, []))
            if node.leftParen == nil {
                node = node.with(\.leftParen, .leftParenToken())
            }
            node = node.with(
                \.arguments,
                node.arguments + [LabeledExprSyntax(expression: declName.asKeyPath)]
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
            if node.isInvalid(standardFunctionsOnly: configuration.restrictToStandardFunctions) {
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

    private var surroundingFunction: FunctionCallExprSyntax? {
           parent?.as(FunctionCallExprSyntax.self)
        ?? parent?.as(LabeledExprSyntax.self)?.parent?.parent?.as(FunctionCallExprSyntax.self)
    }

    func isInvalid(standardFunctionsOnly: Bool) -> Bool {
           keyPathInParent == \FunctionCallExprSyntax.calledExpression
        || parent?.is(MultipleTrailingClosureElementSyntax.self) == true
        || surroundingFunction?.additionalTrailingClosures.isNotEmpty == true
        || standardFunctionsOnly && surroundingFunction?.isStandardFunction == false
    }
}

private extension FunctionCallExprSyntax {
    var isStandardFunction: Bool {
        let declRef = calledExpression.as(DeclReferenceExprSyntax.self)
            ?? calledExpression.as(MemberAccessExprSyntax.self)?.declName
        if let declRef {
            return ["map", "filter", "reduce"].contains(declRef.baseName.text)
        }
        return false
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
