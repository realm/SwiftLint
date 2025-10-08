import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct AsyncWithoutAwaitRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "async_without_await",
        name: "Async Without Await",
        description: "Declaration should not be async if it doesn't use await",
        kind: .lint,
        nonTriggeringExamples: AsyncWithoutAwaitRuleExamples.nonTriggeringExamples,
        triggeringExamples: AsyncWithoutAwaitRuleExamples.triggeringExamples,
        corrections: AsyncWithoutAwaitRuleExamples.corrections
    )
}
private extension AsyncWithoutAwaitRule {
    private struct FuncInfo {
        var containsAwait = false
        let asyncToken: TokenSyntax?
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var functionScopes = Stack<FuncInfo>()
        private var pendingAsync: TokenSyntax?

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.body != nil else {
                return .visitChildren
            }

            // @concurrent functions require the async keyword even without await calls
            let asyncToken = node.attributes.contains(attributeNamed: "concurrent")
                ? nil : node.signature.effectSpecifiers?.asyncSpecifier
            functionScopes.push(.init(asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.body != nil {
                checkViolation()
            }
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            // @concurrent closures require the async keyword even without await calls
            let asyncToken = (node.signature?.attributes.contains(attributeNamed: "concurrent") ?? false)
                ? nil : pendingAsync
            functionScopes.push(.init(asyncToken: asyncToken))
            pendingAsync = nil
            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
            checkViolation()
        }

        override func visitPost(_: AwaitExprSyntax) {
            functionScopes.modifyLast { $0.containsAwait = true }
        }

        override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.body != nil else {
                return .visitChildren
            }

            let asyncToken = node.effectSpecifiers?.asyncSpecifier
            functionScopes.push(.init(asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_ node: AccessorDeclSyntax) {
            if node.body != nil {
                checkViolation()
            }
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.body != nil else {
                return .visitChildren
            }

            // @concurrent can be applied to initializers
            let asyncToken = node.attributes.contains(attributeNamed: "concurrent")
                ? nil : node.signature.effectSpecifiers?.asyncSpecifier
            functionScopes.push(.init(asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if node.body != nil {
                checkViolation()
            }
        }

        override func visitPost(_ node: ForStmtSyntax) {
            if node.awaitKeyword != nil {
                functionScopes.modifyLast { $0.containsAwait = true }
            }
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.bindingSpecifier.tokenKind == .keyword(.let) {
                pendingAsync = node.bindings.onlyElement?.typeAnnotation?.type.asyncToken
            }
            return .visitChildren
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard node.bindingSpecifier.tokenKind == .keyword(.let) else {
                return
            }
            if node.modifiers.contains(keyword: .async) {
                functionScopes.modifyLast { $0.containsAwait = true }
            }
            if pendingAsync == node.bindings.onlyElement?.typeAnnotation?.type.asyncToken {
                if node.bindings.onlyElement?.initializer != nil {
                    functionScopes.push(.init(asyncToken: pendingAsync))
                    checkViolation()
                }
                pendingAsync = nil
            }
        }

        override func visit(_: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        private func checkViolation() {
            guard let info = functionScopes.pop(),
                  let asyncToken = info.asyncToken,
                  !info.containsAwait else {
                return
            }

            violations.append(
                at: asyncToken.positionAfterSkippingLeadingTrivia,
                correction: .init(
                    start: asyncToken.positionAfterSkippingLeadingTrivia,
                    end: asyncToken.endPosition,
                    replacement: ""
                )
            )
        }
    }
}

private extension TypeSyntax {
    var asyncToken: TokenSyntax? {
        if let functionType = `as`(FunctionTypeSyntax.self) {
            return functionType.effectSpecifiers?.asyncSpecifier
        }
        if let optionalType = `as`(OptionalTypeSyntax.self) {
            return optionalType.wrappedType.asyncToken
        }
        if let tupleType = `as`(TupleTypeSyntax.self) {
            return tupleType.elements.onlyElement?.type.asyncToken
        }
        return nil
    }
}
