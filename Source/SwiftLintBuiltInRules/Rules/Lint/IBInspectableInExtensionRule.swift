import SwiftSyntax

struct IBInspectableInExtensionRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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
            """)
        ],
        triggeringExamples: [
            Example("""
            extension Foo {
              ↓@IBInspectable private var x: Int
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension IBInspectableInExtensionRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            .allExcept(ExtensionDeclSyntax.self, VariableDeclSyntax.self)
        }

        override func visitPost(_ node: AttributeSyntax) {
            if node.attributeName.text == "IBInspectable" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
