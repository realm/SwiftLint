import SwiftSyntax
import SwiftSyntaxBuilder

struct NoDefaultSwitchInOperatorsRule: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_default_switch_in_operators",
        name: "Don't use 'default' in operators",
        description: "Don't use default in operator definitions to avoid the risk of forgetting to add new cases",
        kind: .lint,
        nonTriggeringExamples: NoDefaultSwitchInOperatorsRuleExamples.nonTriggeringExamples,
        triggeringExamples: NoDefaultSwitchInOperatorsRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private final class Visitor: ViolationsSyntaxVisitor {
    override func visitPost(_ node: FunctionDeclSyntax) {
        guard case .binaryOperator = node.identifier.tokenKind else {
            return
        }

        let defaultCaseVisitor = HasDefaultCaseVisitor()
        defaultCaseVisitor.walk(node)
        for location in defaultCaseVisitor.defaultCaseLocations {
            self.violations.append(location)
        }
    }
}

private final class HasDefaultCaseVisitor: SyntaxVisitor {
    var defaultCaseLocations: [AbsolutePosition] = []

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: SwitchCaseSyntax) {
        if node.unknownAttr == nil && node.label.as(SwitchDefaultLabelSyntax.self) != nil {
            defaultCaseLocations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
