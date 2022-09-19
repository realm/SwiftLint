import SwiftSyntax

public struct IBInspectableInExtensionRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "ibinspectable_in_extension",
        name: "IBInspectable in Extension",
        description: "Extensions shouldn't add @IBInspectable properties.",
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension IBInspectableInExtensionRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            .visitChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visitPost(_ node: AttributeSyntax) {
            if node.attributeName.text == "IBInspectable" {
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
