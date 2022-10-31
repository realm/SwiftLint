import SwiftSyntax

public struct QuickDiscouragedFocusedTestRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "quick_discouraged_focused_test",
        name: "Quick Discouraged Focused Test",
        description: "Discouraged focused test. Other tests won't run while this one is focused.",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedFocusedTestRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedFocusedTestRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension QuickDiscouragedFocusedTestRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
               case let name = identifierExpr.identifier.withoutTrivia().text,
               QuickFocusedCallKind(rawValue: name) != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            node.containsInheritance ? .visitChildren : .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isQuickSpecFunction ? .visitChildren : .skipChildren
        }
    }
}

private enum QuickFocusedCallKind: String {
    case fdescribe
    case fcontext
    case fit
    case fitBehavesLike
}
