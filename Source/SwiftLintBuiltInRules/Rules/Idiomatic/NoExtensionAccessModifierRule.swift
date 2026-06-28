import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct NoExtensionAccessModifierRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "no_extension_access_modifier",
        name: "No Extension Access Modifier",
        description: "Prefer not to use extension access modifiers",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "extension String {}",
            "\n\n extension String {}",
            "nonisolated extension String {}",
        ]),
        triggeringExamples: #examples([
            "↓private extension String {}",
            "↓public \n extension String {}",
            "↓open extension String {}",
            "↓internal extension String {}",
            "↓fileprivate extension String {}",
        ])
    )
}

private extension NoExtensionAccessModifierRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            let modifiers = node.modifiers
            if let accessLevelModifier = modifiers.accessLevelModifier {
                violations.append(accessLevelModifier.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
