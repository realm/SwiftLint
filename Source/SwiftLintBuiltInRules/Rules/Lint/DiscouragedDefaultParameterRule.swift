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
        nonTriggeringExamples: #examples([
            "public func foo(bar: Int = 0) {}",
            "open func foo(bar: Int = 0) {}",
            "public extension Foo { func foo(bar: Int = 0) {} }",
            "extension E { public func foo(bar: Int = 0) {} }",
            "func outer() { func inner(bar: Int = 0) {} }",
            "func foo(bar: Int) {}",
            "private func foo(bar: Int = 0) {}",
            "fileprivate func foo(bar: Int = 0) {}",
            "public init(value: Int = 42) {}",
            "func foo(bar: Int = 0) {}".configuration(["disallowed_access_levels": ["private"]]),
        ]),
        triggeringExamples: #examples([
            "func foo(bar: Int ↓= 0) {}",
            "internal func foo(bar: Int ↓= 0) {}",
            "package func foo(bar: Int ↓= 0) {}",
            "func foo(bar: Int ↓= 0, baz: String ↓= \"\") {}",
            "init(value: Int ↓= 42) {}",
            "class C { public func foo(bar: Int ↓= 0) {} }",
            "struct S { public init(value: Int ↓= 42) {} }",
            "private func foo(bar: Int ↓= 0) {}".configuration(["disallowed_access_levels": ["private"]]),
            "fileprivate func foo(bar: Int ↓= 0) {}".configuration(["disallowed_access_levels": ["fileprivate"]]),
        ])
    )
}

private extension DiscouragedDefaultParameterRule {
    final class Visitor: EffectiveAccessControlSyntaxVisitor<ConfigurationType> {
        init(configuration: ConfigurationType, file: SwiftLintFile) {
            super.init(configuration: configuration, file: file)
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolations(modifiers: node.modifiers, parameterClause: node.signature.parameterClause)
            return .skipChildren
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolations(modifiers: node.modifiers, parameterClause: node.signature.parameterClause)
            return .skipChildren
        }

        override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolations(modifiers: node.modifiers, parameterClause: node.parameterClause)
            return .skipChildren
        }

        private func collectViolations(modifiers: DeclModifierListSyntax,
                                       parameterClause: FunctionParameterClauseSyntax) {
            guard !isInLocalAccessControlScope,
                  case let accessLevel = effectiveAccessControlLevel(for: modifiers),
                  configuration.disallowedAccessLevels.contains(accessLevel) else {
                return
            }
            for param in parameterClause.parameters {
                if let defaultValue = param.defaultValue {
                    violations.append(
                        .init(
                            position: defaultValue.positionAfterSkippingLeadingTrivia,
                            reason: "Default parameter values should not be used in '\(accessLevel)' functions"
                        )
                    )
                }
            }
        }
    }
}
