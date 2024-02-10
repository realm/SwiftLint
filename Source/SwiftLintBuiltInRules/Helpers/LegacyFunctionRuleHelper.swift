import SwiftSyntax
import SwiftSyntaxBuilder

/// A helper to hold a visitor and rewriter that can lint and correct legacy NS/CG functions to a more modern syntax.
enum LegacyFunctionRuleHelper {
    final class Visitor<Configuration: RuleConfiguration>: ViolationsSyntaxVisitor<Configuration> {
        private let legacyFunctions: [String: RewriteStrategy]

        init(configuration: Configuration, file: SwiftLintFile, legacyFunctions: [String: RewriteStrategy]) {
            self.legacyFunctions = legacyFunctions
            super.init(configuration: configuration, file: file)
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.isLegacyFunctionExpression(legacyFunctions: legacyFunctions) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    enum RewriteStrategy {
        case equal
        case property(name: String)
        case function(name: String, argumentLabels: [String], reversed: Bool = false)

        var expectedInitialArguments: Int {
            switch self {
            case .equal:
                return 2
            case .property:
                return 1
            case .function(name: _, argumentLabels: let argumentLabels, reversed: _):
                return argumentLabels.count + 1
            }
        }
    }

    final class Rewriter<Configuration: RuleConfiguration>: ViolationsSyntaxRewriter<Configuration> {
        private let legacyFunctions: [String: RewriteStrategy]

        init(
            legacyFunctions: [String: RewriteStrategy],
            configuration: Configuration,
            file: SwiftLintFile
        ) {
            self.legacyFunctions = legacyFunctions
            super.init(configuration: configuration, file: file)
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard node.isLegacyFunctionExpression(legacyFunctions: legacyFunctions),
                  let funcName = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)

            let trimmedArguments = node.arguments.map { $0.trimmingTrailingComma() }
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
}

private extension FunctionCallExprSyntax {
    func isLegacyFunctionExpression(legacyFunctions: [String: LegacyFunctionRuleHelper.RewriteStrategy]) -> Bool {
        guard
            let calledExpression = calledExpression.as(DeclReferenceExprSyntax.self),
            let rewriteStrategy = legacyFunctions[calledExpression.baseName.text],
            arguments.count == rewriteStrategy.expectedInitialArguments
        else {
            return false
        }

        return true
    }
}

private extension LabeledExprSyntax {
    func trimmingTrailingComma() -> LabeledExprSyntax {
        self.trimmed.with(\.trailingComma, nil).trimmed
    }
}
