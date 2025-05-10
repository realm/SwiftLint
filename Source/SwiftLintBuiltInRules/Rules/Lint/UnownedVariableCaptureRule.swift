import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct UnownedVariableCaptureRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unowned_variable_capture",
        name: "Unowned Variable Capture",
        description: "Prefer capturing references as weak to avoid potential crashes",
        kind: .lint,
        nonTriggeringExamples: [
            Example("foo { [weak self] in _ }"),
            Example("foo { [weak self] param in _ }"),
            Example("foo { [weak bar] in _ }"),
            Example("foo { [weak bar] param in _ }"),
            Example("foo { bar in _ }"),
            Example("foo { $0 }"),
            Example("""
            final class First {}
            final class Second {
                unowned var value: First
                init(value: First) {
                    self.value = value
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("foo { [↓unowned self] in _ }"),
            Example("foo { [↓unowned bar] in _ }"),
            Example("foo { [bar, ↓unowned self] in _ }"),
        ]
    )
}

private extension UnownedVariableCaptureRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TokenSyntax) {
            if case .keyword(.unowned) = node.tokenKind, node.parent?.is(ClosureCaptureSpecifierSyntax.self) == true {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
