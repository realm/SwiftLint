import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct IBInspectableInExtensionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "ibinspectable_in_extension",
        name: "IBInspectable in Extension",
        description: "Extensions shouldn't add @IBInspectable properties",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class Foo {
              @IBInspectable private var x: Int
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            extension Foo {
              ↓@IBInspectable private var x: Int
            }
            """),
        ]
    )
}

private extension IBInspectableInExtensionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            .allExcept(ExtensionDeclSyntax.self, VariableDeclSyntax.self)
        }

        override func visitPost(_ node: AttributeSyntax) {
            if node.attributeNameText == "IBInspectable" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
