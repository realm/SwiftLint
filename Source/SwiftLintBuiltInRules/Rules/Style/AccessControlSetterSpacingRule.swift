import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct AccessControlSetterSpacingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "access_control_setter_spacing",
        name: "Access Control Setter Spacing",
        description: "There should be no space between the access control modifier and setter scope",
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
            guard let _ = node.asAccessLevelModifier, node.detail?.detail.tokenKind == .identifier("set"), node.name.trailingTrivia.isNotEmpty else {
                return
            }

            violations.append(node.name.endPosition)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
            guard let _ = node.asAccessLevelModifier, node.detail?.detail.tokenKind == .identifier("set"), node.name.trailingTrivia.isNotEmpty else {
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
