import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct DisallowDefaultParameterRule: Rule {
    var configuration = DisallowDefaultParameterConfiguration()

    static let description = RuleDescription(
        identifier: "disallow_default_parameter",
        name: "Disallow Default Parameter",
        description: "Default parameter values should not be used in functions with certain access levels",
        kind: .idiomatic,
        nonTriggeringExamples: DisallowDefaultParameterRuleExamples.nonTriggeringExamples,
        triggeringExamples: DisallowDefaultParameterRuleExamples.triggeringExamples
    )
}

private extension DisallowDefaultParameterRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            collectViolations(modifiers: node.modifiers, signature: node.signature)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            collectViolations(modifiers: node.modifiers, signature: node.signature)
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            guard matchesDisallowedAccessLevel(node.modifiers) else { return }
            for param in node.parameterClause.parameters where param.defaultValue != nil {
                violations.append(param.defaultValue!.positionAfterSkippingLeadingTrivia)
            }
        }

        private func collectViolations(
            modifiers: DeclModifierListSyntax,
            signature: FunctionSignatureSyntax
        ) {
            guard matchesDisallowedAccessLevel(modifiers) else { return }
            for param in signature.parameterClause.parameters where param.defaultValue != nil {
                violations.append(param.defaultValue!.positionAfterSkippingLeadingTrivia)
            }
        }

        private func matchesDisallowedAccessLevel(_ modifiers: DeclModifierListSyntax) -> Bool {
            let disallowed = configuration.disallowedAccessLevels
            // Determine the effective access level from modifiers
            if modifiers.contains(keyword: .private) {
                return disallowed.contains(.private)
            }
            if modifiers.contains(keyword: .fileprivate) {
                return disallowed.contains(.fileprivate)
            }
            if modifiers.contains(keyword: .package) {
                return disallowed.contains(.package)
            }
            if modifiers.contains(keyword: .public) || modifiers.contains(keyword: .open) {
                return false // public/open are never disallowed
            }
            // No explicit access modifier means `internal`
            return disallowed.contains(.internal)
        }
    }
}
