import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct UnownedVariableCaptureRule: Rule {
    var configuration = UnownedVariableCaptureConfiguration()

    static let description = RuleDescription(
        identifier: "unowned_variable_capture",
        name: "Unowned Variable Capture",
        description: "Prefer capturing references as weak to avoid potential crashes",
        kind: .lint,
        nonTriggeringExamples: #examples([
            "foo { [weak self] in _ }",
            "foo { [weak self] param in _ }",
            "foo { [weak bar] in _ }",
            "foo { [weak bar] param in _ }",
            "foo { [unowned(unsafe) self] in _ }",
            "foo { bar in _ }",
            "foo { $0 }",
            """
            final class First {}
            final class Second {
                unowned var value: First
                init(value: First) {
                    self.value = value
                }
            }
            """,
        ]),
        triggeringExamples: #examples([
            "foo { [↓unowned self] in _ }",
            "foo { [↓unowned bar] in _ }",
            "foo { [↓unowned(safe) self] in _ }",
            "foo { [bar, ↓unowned self] in _ }",
            "foo { [↓unowned(unsafe) self] in _ }"
                .asExample(configuration: ["include_unsafe": true]),
        ])
    )
}

private extension UnownedVariableCaptureRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TokenSyntax) {
            guard case .keyword(.unowned) = node.tokenKind,
                  let specifier = node.parent?.as(ClosureCaptureSpecifierSyntax.self) else {
                return
            }

            let isUnsafe = specifier.tokens(viewMode: .sourceAccurate).contains { $0.text == "unsafe" }
            if !isUnsafe || configuration.includeUnsafe {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
