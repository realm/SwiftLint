import SwiftSyntax

@SwiftSyntaxRule
struct AccessControlSetterSpacingRule: SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "access_control_setter_spacing",
        name: "Access Control Setter Spacing",
        description: "Files should not contain leading whitespace",
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
        ]//,
//        corrections: [
//            Example("private ↓(set) var foo: Bool = false"): Example("private(set) var foo: Bool = false"),
//            Example("fileprivate ↓(set) var foo: Bool = false"): Example("fileprivate(set) var foo: Bool = false"),
//            Example("internal ↓(set) var foo: Bool = false"): Example("internal(set) var foo: Bool = false"),
//            Example("public ↓(set) var foo: Bool = false"): Example("public(set) var foo: Bool = false"),
//            Example("open ↓(set) var foo: Bool = false"): Example("open(set) var foo: Bool = false"),
//        ]
    )
}

private extension AccessControlSetterSpacingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclModifierSyntax) {
            // If there is an access level modifier followed be a (set)
            guard let _ = node.asAccessLevelModifier, let detail = node.detail, detail.detail.tokenKind == .identifier("set") else {
                return
            }

            if node.name.trailingTrivia.isNotEmpty {
                violations.append(node.name.endPosition)
            }
        }
    }
}
