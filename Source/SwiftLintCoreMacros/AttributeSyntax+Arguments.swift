import SwiftSyntax
import SwiftSyntaxMacros

extension AttributeSyntax {
    func isArgumentTrue(withName name: String, in context: some MacroExpansionContext) -> Bool {
        if let expr = argument(withName: name) {
            if expr.isBooleanLiteral {
                return expr.isTrueLiteral
            }
            context.diagnose(SwiftLintCoreMacroError.noBooleanLiteral.diagnose(at: expr))
        }
        return false
    }

    func argument(withName name: String) -> ExprSyntax? {
        if case let .argumentList(args) = arguments,
           let first = args.first(where: { $0.label?.text == name }) {
            return first.expression
        }
        return nil
    }
}

extension ExprSyntax {
    var isBooleanLiteral: Bool {
        `is`(BooleanLiteralExprSyntax.self)
    }

    var isTrueLiteral: Bool {
        `as`(BooleanLiteralExprSyntax.self)?.literal.text == "true"
    }
}
