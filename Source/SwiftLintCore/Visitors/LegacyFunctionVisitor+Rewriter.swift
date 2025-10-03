import SwiftSyntax
import SwiftSyntaxBuilder

/// Visitor that collects violations when legacy functions are called.
open class LegacyFunctionVisitor<Configuration: RuleConfiguration>: ViolationsSyntaxVisitor<Configuration> {
    @usableFromInline let legacyFunctions: [String: LegacyFunctionRewriteStrategy]

    /// Initializer for a ``ViolationsSyntaxVisitor``.
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: File from which the syntax tree stems from.
    ///   - legacyFunctions: A dictionary mapping legacy function names to their rewrite strategies.
    @inlinable
    public init(configuration: Configuration,
                file: SwiftLintFile,
                legacyFunctions: [String: LegacyFunctionRewriteStrategy]) {
        self.legacyFunctions = legacyFunctions
        super.init(configuration: configuration, file: file)
    }

    override open func visitPost(_ node: FunctionCallExprSyntax) {
        if node.isLegacyFunctionExpression(legacyFunctions: legacyFunctions) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

/// Strategy to apply when rewriting a legacy function call.
public enum LegacyFunctionRewriteStrategy: Sendable {
    /// Replace with equality check between the two arguments.
    case equal
    /// Replace with property access with name ``name`` on the argument.
    case property(name: String)
    /// Replace with method call with name ``name`` on the first argument, passing the remaining arguments
    /// with the specified ``argumentLabels``. If ``reversed`` is `true`, the order of arguments is reversed, that
    /// is, the function is called on the second argument, passing the first argument as parameter.
    case function(name: String, argumentLabels: [String], reversed: Bool = false)

    fileprivate var expectedInitialArguments: Int {
        switch self {
        case .equal: 2
        case .property: 1
        case .function(name: _, argumentLabels: let argumentLabels, reversed: _): argumentLabels.count + 1
        }
    }
}

/// Rewriter that corrects legacy function calls to their modern equivalents.
open class LegacyFunctionRewriter<Configuration: RuleConfiguration>: ViolationsSyntaxRewriter<Configuration> {
    @usableFromInline let legacyFunctions: [String: LegacyFunctionRewriteStrategy]

    /// Initializer for a ``ViolationsSyntaxRewriter``.
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: File from which the syntax tree stems from.
    ///   - legacyFunctions: A dictionary mapping legacy function names to their rewrite strategies.
    @inlinable
    public init(configuration: Configuration,
                file: SwiftLintFile,
                legacyFunctions: [String: LegacyFunctionRewriteStrategy]) {
        self.legacyFunctions = legacyFunctions
        super.init(configuration: configuration, file: file)
    }

    override open func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard node.isLegacyFunctionExpression(legacyFunctions: legacyFunctions),
              let funcName = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text else {
            return super.visit(node)
        }
        numberOfCorrections += 1
        let trimmedArguments = node.arguments.map(\.trimmingTrailingComma)
        let rewriteStrategy = legacyFunctions[funcName]
        let expr: ExprSyntax
        switch rewriteStrategy {
        case .equal:
            expr = "\(trimmedArguments[0]) == \(trimmedArguments[1])"
        case let .property(name: propertyName):
            expr = "\(trimmedArguments[0]).\(raw: propertyName)"
        case let .function(name: functionName, argumentLabels: argumentLabels, reversed: reversed):
            let arguments = reversed ? trimmedArguments.reversed() : trimmedArguments
            let params = zip(argumentLabels, arguments.dropFirst())
                .map { $0.isEmpty ? "\($1)" : "\($0): \($1)" }
                .joined(separator: ", ")
            expr = "\(arguments[0]).\(raw: functionName)(\(raw: params))"
        case .none:
            return super.visit(node)
        }

        return expr
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
    }
}

private extension FunctionCallExprSyntax {
    func isLegacyFunctionExpression(legacyFunctions: [String: LegacyFunctionRewriteStrategy]) -> Bool {
        guard let calledExpression = calledExpression.as(DeclReferenceExprSyntax.self),
              let rewriteStrategy = legacyFunctions[calledExpression.baseName.text],
              arguments.count == rewriteStrategy.expectedInitialArguments else {
            return false
        }
        return true
    }
}

private extension LabeledExprSyntax {
    var trimmingTrailingComma: LabeledExprSyntax {
        trimmed.with(\.trailingComma, nil).trimmed
    }
}
