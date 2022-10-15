import SwiftSyntax

public struct QuickDiscouragedPendingTestRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "quick_discouraged_pending_test",
        name: "Quick Discouraged Pending Test",
        description: "Discouraged pending test. This test won't run while it's marked as pending.",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedPendingTestRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedPendingTestRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension QuickDiscouragedPendingTestRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
               case let name = identifierExpr.identifier.withoutTrivia().text,
               QuickPendingCallKind(rawValue: name) != nil {
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isQuickSpec ? .visitChildren : .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isSpecFunction ? .visitChildren : .skipChildren
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
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

private enum QuickPendingCallKind: String {
    case pending
    case xdescribe
    case xcontext
    case xit
    case xitBehavesLike
}
