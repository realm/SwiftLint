import SwiftSyntax

public struct NoExtensionAccessModifierRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_extension_access_modifier",
        name: "No Extension Access Modifier",
        description: "Prefer not to use extension access modifiers",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("extension String {}"),
            Example("\n\n extension String {}")
        ],
        triggeringExamples: [
            Example("↓private extension String {}"),
            Example("↓public \n extension String {}"),
            Example("↓open extension String {}"),
            Example("↓internal extension String {}"),
            Example("↓fileprivate extension String {}")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NoExtensionAccessModifierRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if let modifiers = node.modifiers, modifiers.isNotEmpty {
                violationPositions.append(modifiers.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
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
