import SwiftSyntax

@SwiftSyntaxRule
struct RedundantExtensionRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_extension",
        name: "Redundant Extension",
        description: "Avoid redundant extensions",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
                    extension Foo {
                        func something() {}
                    }
                    """),
            Example("""
                    extension Foo {
                        var a: Int { 1 }
                    }
                    """),
            Example("""
                    extension Foo {
                        final class Bar {}
                    }
                    """)
        ],
        triggeringExamples: [
            Example("""
                    ↓extension Bar {}
                    """)
        ]
    )
}

private extension RedundantExtensionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ExtensionDeclSyntax) {
            if node.memberBlock.members.isEmpty {
                violations.append(node.extensionKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
