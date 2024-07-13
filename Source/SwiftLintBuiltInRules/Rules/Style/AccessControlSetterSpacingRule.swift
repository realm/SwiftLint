import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct AccessControlSetterSpacingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "access_control_setter_spacing",
        name: "Access Control Setter Spacing",
        description: "There should not be a space between the access control modifier and (set)",
        kind: .style,
        nonTriggeringExamples: [
            Example("private(set) var foo: Bool = false"),
            Example("fileprivate(set) var foo: Bool = false"),
            Example("internal(set) var foo: Bool = false"),
            Example("public(set) var foo: Bool = false"),
            Example("open(set) var foo: Bool = false"),
        ],
        triggeringExamples: [
            Example("private ↓(set) var foo: Bool = false"),
            Example("fileprivate ↓(set) var foo: Bool = false"),
            Example("internal ↓(set) var foo: Bool = false"),
            Example("public ↓(set) var foo: Bool = false"),
            Example("  public  ↓(set) var foo: Bool = false"),
        ],
        corrections: [
            Example("private ↓(set) var foo: Bool = false"): Example("private(set) var foo: Bool = false"),
            Example("fileprivate ↓(set) var foo: Bool = false"): Example("fileprivate(set) var foo: Bool = false"),
            Example("internal ↓(set) var foo: Bool = false"): Example("internal(set) var foo: Bool = false"),
            Example("public ↓(set) var foo: Bool = false"): Example("public(set) var foo: Bool = false"),
        ]
    )
}

private extension AccessControlSetterSpacingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclModifierSyntax) {
            // If there is an access level modifier followed be a (set)
            guard let _ = node.asAccessLevelModifier, node.detail?.detail.tokenKind == .identifier("set") else {
                return
            }

            if node.name.trailingTrivia.isNotEmpty {
                violations.append(node.name.endPosition)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
            guard node.name.trailingTrivia.isNotEmpty else {
                return super.visit(node)
            }

            correctionPositions.append(node.name.endPosition)

            // Remove trailing whitespace from the name token
            let cleanedName = node.name.with(\.trailingTrivia, Trivia())
            let newNode = node.with(\.name, cleanedName)
            return super.visit(newNode)
        }
    }
}
