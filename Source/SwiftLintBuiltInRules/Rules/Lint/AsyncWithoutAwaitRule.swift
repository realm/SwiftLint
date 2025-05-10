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

        init(asyncToken: TokenSyntax?) {
            self.asyncToken = asyncToken
        }
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var functionScopes = Stack<FuncInfo>()
        private var pendingAsync: TokenSyntax?

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.body != nil else {
                return .visitChildren
            }

            let asyncToken = node.signature.effectSpecifiers?.asyncSpecifier
            functionScopes.push(.init(asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.body != nil {
                checkViolation()
            }
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            functionScopes.push(.init(asyncToken: pendingAsync))
            pendingAsync = nil

            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
            checkViolation()
        }

        override func visitPost(_: AwaitExprSyntax) {
            functionScopes.modifyLast {
                $0.containsAwait = true
            }
        }

        override func visitPost(_ node: FunctionTypeSyntax) {
            if let asyncNode = node.effectSpecifiers?.asyncSpecifier {
                pendingAsync = asyncNode
            }
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

        override func visitPost(_: PatternBindingSyntax) {
            pendingAsync = nil
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.body != nil else {
                return .visitChildren
            }

            let asyncToken = node.signature.effectSpecifiers?.asyncSpecifier
            functionScopes.push(.init(asyncToken: asyncToken))

            return .visitChildren
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if node.body != nil {
                checkViolation()
            }
        }

        override func visitPost(_: TypeAliasDeclSyntax) {
            pendingAsync = nil
        }

        override func visitPost(_ node: ForStmtSyntax) {
            if node.awaitKeyword != nil {
                functionScopes.modifyLast {
                    $0.containsAwait = true
                }
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.bindingSpecifier.tokenKind == .keyword(.let),
                node.modifiers.contains(keyword: .async) {
                functionScopes.modifyLast {
                    $0.containsAwait = true
                }
            }
        }

        override func visit(_: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visitPost(_: ReturnClauseSyntax) {
            pendingAsync = nil
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
