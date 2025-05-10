import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct NoExtensionAccessModifierRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "no_extension_access_modifier",
        name: "No Extension Access Modifier",
        description: "Prefer not to use extension access modifiers",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("extension String {}"),
            Example("\n\n extension String {}"),
        ],
        triggeringExamples: [
            Example("↓private extension String {}"),
            Example("↓public \n extension String {}"),
            Example("↓open extension String {}"),
            Example("↓internal extension String {}"),
            Example("↓fileprivate extension String {}"),
        ]
    )
}

private extension NoExtensionAccessModifierRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            let modifiers = node.modifiers
            if modifiers.isNotEmpty {
                violations.append(modifiers.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
