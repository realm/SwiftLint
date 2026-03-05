import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct DiscouragedDefaultParameterRule: Rule {
    var configuration = DiscouragedDefaultParameterConfiguration()

    static let description = RuleDescription(
        identifier: "discouraged_default_parameter",
        name: "Discouraged Default Parameter",
        description: "Default parameter values should not be used in functions with certain access levels.",
        rationale: """
            By discouraging default parameter values in functions, that are exposed to other source files in the module
            or package and their consumers, we can promote call sites and reduce the likelihood of bugs caused by
            unexpected (or changed) default values being used.
            """,
        kind: .lint,
        nonTriggeringExamples: [
            Example("public func foo(bar: Int = 0) {}"),
            Example("open func foo(bar: Int = 0) {}"),
            Example("func foo(bar: Int) {}"),
            Example("private func foo(bar: Int = 0) {}"),
            Example("fileprivate func foo(bar: Int = 0) {}"),
            Example("public init(value: Int = 42) {}"),
            Example(
                "func foo(bar: Int = 0) {}",
                configuration: ["disallowed_access_levels": ["private"]]
            ),
        ],
        triggeringExamples: [
            Example("func foo(bar: Int ↓= 0) {}"),
            Example("internal func foo(bar: Int ↓= 0) {}"),
            Example("package func foo(bar: Int ↓= 0) {}"),
            Example("func foo(bar: Int ↓= 0, baz: String ↓= \"\") {}"),
            Example("init(value: Int ↓= 42) {}"),
            Example(
                "private func foo(bar: Int ↓= 0) {}",
                configuration: ["disallowed_access_levels": ["private"]]
            ),
            Example(
                "fileprivate func foo(bar: Int ↓= 0) {}",
                configuration: ["disallowed_access_levels": ["fileprivate"]]
            ),
        ]
    )
}

private extension DiscouragedDefaultParameterRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            collectViolations(modifiers: node.modifiers, parameterClause: node.signature.parameterClause)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            collectViolations(modifiers: node.modifiers, parameterClause: node.signature.parameterClause)
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            collectViolations(modifiers: node.modifiers, parameterClause: node.parameterClause)
        }

        private func collectViolations(
            modifiers: DeclModifierListSyntax,
            parameterClause: FunctionParameterClauseSyntax
        ) {
            guard let accessLevel = effectiveAccessLevel(modifiers),
                  configuration.disallowedAccessLevels.contains(accessLevel) else {
                return
            }
            let levelName = accessLevel.rawValue
            for param in parameterClause.parameters {
                if let defaultValue = param.defaultValue {
                    violations.append(
                        ReasonedRuleViolation(
                            position: defaultValue.positionAfterSkippingLeadingTrivia,
                            reason: "Default parameter values should not be used in '\(levelName)' functions"
                        )
                    )
                }
            }
        }

        private func effectiveAccessLevel(_ modifiers: DeclModifierListSyntax)
            -> DiscouragedDefaultParameterConfiguration.AccessLevel? {
            if modifiers.contains(keyword: .private) { return .private }
            if modifiers.contains(keyword: .fileprivate) { return .fileprivate }
            if modifiers.contains(keyword: .package) { return .package }
            if modifiers.contains(keyword: .public) || modifiers.contains(keyword: .open) { return nil }
            return .internal
        }
    }
}
