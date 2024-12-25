import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct QuickDiscouragedFocusedTestRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "quick_discouraged_focused_test",
        name: "Quick Discouraged Focused Test",
        description: "Non-focused tests won't run as long as this test is focused",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedFocusedTestRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedFocusedTestRuleExamples.triggeringExamples
    )
}

private extension QuickDiscouragedFocusedTestRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
               case let name = identifierExpr.baseName.text,
               QuickFocusedCallKind(rawValue: name) != nil {
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

private enum QuickFocusedCallKind: String {
    case fdescribe
    case fcontext
    case fit
    case fitBehavesLike
}
