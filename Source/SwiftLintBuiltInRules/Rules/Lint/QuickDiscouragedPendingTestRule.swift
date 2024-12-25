import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct QuickDiscouragedPendingTestRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "quick_discouraged_pending_test",
        name: "Quick Discouraged Pending Test",
        description: "This test won't run as long as it's marked pending",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedPendingTestRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedPendingTestRuleExamples.triggeringExamples
    )
}

private extension QuickDiscouragedPendingTestRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
               case let name = identifierExpr.baseName.text,
               QuickPendingCallKind(rawValue: name) != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            node.containsInheritance ? .visitChildren : .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isSpecFunction ? .visitChildren : .skipChildren
        }
    }
}

private extension ClassDeclSyntax {
    var containsInheritance: Bool {
        guard let inheritanceList = inheritanceClause?.inheritedTypes else {
            return false
        }

        return inheritanceList.isNotEmpty
    }
}

private extension FunctionDeclSyntax {
    var isSpecFunction: Bool {
        name.tokenKind == .identifier("spec") &&
        signature.parameterClause.parameters.isEmpty &&
            modifiers.contains(keyword: .override)
    }
}

private enum QuickPendingCallKind: String {
    case pending
    case xdescribe
    case xcontext
    case xit
    case xitBehavesLike
}
