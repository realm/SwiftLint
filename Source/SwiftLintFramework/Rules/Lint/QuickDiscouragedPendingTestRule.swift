import SwiftSyntax

struct QuickDiscouragedPendingTestRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "quick_discouraged_pending_test",
        name: "Quick Discouraged Pending Test",
        description: "This test won't run as long as it's marked pending",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedPendingTestRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedPendingTestRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension QuickDiscouragedPendingTestRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
               case let name = identifierExpr.identifier.text,
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
        guard let inheritanceList = inheritanceClause?.inheritedTypeCollection else {
            return false
        }

        return inheritanceList.isNotEmpty
    }
}

private extension FunctionDeclSyntax {
    var isSpecFunction: Bool {
        return identifier.tokenKind == .identifier("spec") &&
            signature.input.parameterList.isEmpty &&
            modifiers.containsOverride
    }
}

private enum QuickPendingCallKind: String {
    case pending
    case xdescribe
    case xcontext
    case xit
    case xitBehavesLike
}
