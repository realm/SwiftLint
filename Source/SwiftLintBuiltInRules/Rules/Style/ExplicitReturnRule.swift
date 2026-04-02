import Foundation
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct ExplicitReturnRule: Rule {
    var configuration = ExplicitReturnConfiguration()

    static let description = RuleDescription(
        identifier: "explicit_return",
        name: "Explicit Return",
        description: "Prefer explicit returns in closures, functions and getters",
        kind: .style,
        nonTriggeringExamples: ExplicitReturnRuleExamples.nonTriggeringExamples,
        triggeringExamples: ExplicitReturnRuleExamples.triggeringExamples,
        corrections: ExplicitReturnRuleExamples.corrections
    )
}

private extension ExplicitReturnRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: AccessorDeclSyntax) {
            if configuration.isKindIncluded(.getter),
               node.accessorSpecifier.tokenKind == .keyword(.get),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if configuration.isKindIncluded(.closure) {
                collectViolation(in: node.statements, isInsideClosure: true)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if configuration.isKindIncluded(.function),
               node.signature.allowsImplicitReturns,
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if configuration.isKindIncluded(.initializer),
               node.optionalMark != nil,
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            if configuration.isKindIncluded(.getter),
               case let .getter(itemList) = node.accessorBlock?.accessors {
                collectViolation(in: itemList)
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if configuration.isKindIncluded(.subscript),
               case let .getter(itemList) = node.accessorBlock?.accessors {
                collectViolation(in: itemList)
            }
        }

        private func collectViolation(in itemList: CodeBlockItemListSyntax, isInsideClosure: Bool = false) {
            guard let onlyItem = itemList.onlyElement?.item,
                  !onlyItem.is(ReturnStmtSyntax.self),
                  Syntax(onlyItem).isProtocol((any ExprSyntaxProtocol).self) else {
                return
            }
            if isInsideClosure, Syntax(onlyItem).isFunctionCallExpr {
                return
            }
            let position = onlyItem.positionAfterSkippingLeadingTrivia
            violations.append(
                at: position,
                correction: .init(
                    start: position,
                    end: position,
                    replacement: "return "
                )
            )
        }
    }
}

private extension Syntax {
    var isFunctionCallExpr: Bool {
        if `is`(FunctionCallExprSyntax.self) {
            return true
        }
        if let tryExpr = `as`(TryExprSyntax.self) {
            return Syntax(tryExpr.expression).isFunctionCallExpr
        }
        if let awaitExpr = `as`(AwaitExprSyntax.self) {
            return Syntax(awaitExpr.expression).isFunctionCallExpr
        }
        return false
    }
}

private extension FunctionSignatureSyntax {
    var allowsImplicitReturns: Bool {
        guard let returnClause else { return false }
        if let identifierType = returnClause.type.as(IdentifierTypeSyntax.self) {
            return identifierType.name.text != "Void" && identifierType.name.text != "Never"
        }
        if let tupleType = returnClause.type.as(TupleTypeSyntax.self) {
            return !tupleType.elements.isEmpty
        }
        return true
    }
}
