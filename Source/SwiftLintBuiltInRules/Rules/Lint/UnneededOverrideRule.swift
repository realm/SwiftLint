import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(explicitRewriter: true)
struct UnneededOverrideRule: Rule {
    var configuration = UnneededOverrideRuleConfiguration()

    static let description = RuleDescription(
        identifier: "unneeded_override",
        name: "Unneeded Overridden Functions",
        description: "Remove overridden functions that don't do anything except call their super",
        kind: .lint,
        nonTriggeringExamples: UnneededOverrideRuleExamples.nonTriggeringExamples,
        triggeringExamples: UnneededOverrideRuleExamples.triggeringExamples,
        corrections: UnneededOverrideRuleExamples.corrections
    )
}

private extension UnneededOverrideRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.isUnneededOverride {
                self.violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if configuration.affectInits && node.isUnneededOverride {
                self.violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            guard node.isUnneededOverride else {
                return super.visit(node)
            }

            return visitUnneededOverride(node)
        }

        override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
            guard configuration.affectInits, node.isUnneededOverride else {
                return super.visit(node)
            }

            return visitUnneededOverride(node)
        }

        private func visitUnneededOverride(_ node: some DeclSyntaxProtocol) -> DeclSyntax {
            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let expr: DeclSyntax = ""
            return expr
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
        }
    }
}

private extension FunctionDeclSyntax {
    var isUnneededOverride: Bool {
        mayBeUnneededOverride(name: name.text)
    }
}

private extension InitializerDeclSyntax {
    var isUnneededOverride: Bool {
        guard
            optionalMark == nil, // init? can be overridden with init! and vice versa.
            !modifiers.contains(keyword: .private) // An initializer can be hidden by overriding it.
        else {
            return false
        }

        return mayBeUnneededOverride(name: "init")
    }
}

private protocol OverridableDecl: WithAttributesSyntax, WithModifiersSyntax {
    var signature: FunctionSignatureSyntax { get }
    var body: CodeBlockSyntax? { get }
}

private extension OverridableDecl {
    /// Perform checks common to all overridable types of declarations.
    func mayBeUnneededOverride(name: String) -> Bool {
        guard modifiers.contains(keyword: .override), let statement = body?.statements.onlyElement else {
            return false
        }

        // Assume attributes change behavior.
        guard attributes.isEmpty else {
            return false
        }

        guard let call = extractFunctionCallSyntax(statement.item),
            let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.base?.is(SuperExprSyntax.self) == true,
              member.declName.baseName.text == name else {
            return false
        }

        guard call.trailingClosure == nil, call.additionalTrailingClosures.isEmpty else {
            // Assume trailing closures change behavior.
            return false
        }

        let declParameters = signature.parameterClause.parameters
        if declParameters.contains(where: { $0.defaultValue != nil }) {
            // Any default parameter might be a change to the super.
            return false
        }

        // Assume any change in arguments passed means behavior was changed.
        let expectedArguments = declParameters.map {
            ($0.firstName.text == "_" ? "" : $0.firstName.text, $0.secondName?.text ?? $0.firstName.text)
        }
        let actualArguments = call.arguments.map {
            ($0.label?.text ?? "", $0.expression.as(DeclReferenceExprSyntax.self)?.baseName.text ?? "")
        }

        guard expectedArguments.count == actualArguments.count else {
            return false
        }

        for (lhs, rhs) in zip(expectedArguments, actualArguments) where lhs != rhs {
            return false
        }

        return true
    }
}

extension FunctionDeclSyntax: OverridableDecl {}

extension InitializerDeclSyntax: OverridableDecl {}

/// Extract the function call from other expressions like try / await / return.
///
/// If this returns a non-super calling function, it will get filtered out later.
private func extractFunctionCallSyntax(_ node: some SyntaxProtocol) -> FunctionCallExprSyntax? {
    var syntax = simplify(node)
    while let nestedSyntax = syntax {
        if nestedSyntax.as(FunctionCallExprSyntax.self) != nil {
            break
        }

        syntax = simplify(nestedSyntax)
    }

    return syntax?.as(FunctionCallExprSyntax.self)
}

private func simplify(_ node: some SyntaxProtocol) -> (any ExprSyntaxProtocol)? {
    if let expr = node.as(AwaitExprSyntax.self) {
        return expr.expression
    }
    if let expr = node.as(TryExprSyntax.self) {
        // Assume using try! / try? changes behavior.
        if expr.questionOrExclamationMark != nil {
            return nil
        }

        return expr.expression
    }
    if let expr = node.as(FunctionCallExprSyntax.self) {
        return expr
    }
    if let stmt = node.as(ReturnStmtSyntax.self) {
        return stmt.expression
    }

    return nil
}
