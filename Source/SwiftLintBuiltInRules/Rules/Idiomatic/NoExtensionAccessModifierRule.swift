import SwiftSyntax

struct NoExtensionAccessModifierRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "no_extension_access_modifier",
        name: "No Extension Access Modifier",
        description: "Prefer not to use extension access modifiers",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "extension String {}",
            "\n\n extension String {}"
        ],
        triggeringExamples: [
            "↓private extension String {}",
            "↓public \n extension String {}",
            "↓open extension String {}",
            "↓internal extension String {}",
            "↓fileprivate extension String {}"
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NoExtensionAccessModifierRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if let modifiers = node.modifiers, modifiers.isNotEmpty {
                violations.append(modifiers.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
