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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
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
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isQuickSpec ? .visitChildren : .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isSpecFunction ? .visitChildren : .skipChildren
        }
    }
}

private extension ClassDeclSyntax {
    var isQuickSpec: Bool {
        guard let inheritanceList = inheritanceClause?.inheritedTypeCollection else {
            return false
        }

        return inheritanceList.contains { type in
            type.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text == "QuickSpec"
        }
    }
}

private extension FunctionDeclSyntax {
    var isSpecFunction: Bool {
        return identifier.tokenKind == .identifier("spec") &&
            signature.input.parameterList.isEmpty &&
            modifiers.containsOverride
    }
}

private extension ModifierListSyntax? {
    var containsOverride: Bool {
        self?.contains { elem in
            elem.name.tokenKind == .contextualKeyword("override")
        } ?? false
    }
}

private enum QuickFocusedCallKind: String {
    case fdescribe
    case fcontext
    case fit
    case fitBehavesLike
}
