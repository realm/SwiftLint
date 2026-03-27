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
            Example("public extension Foo { func foo(bar: Int = 0) {} }"),
            Example("extension E { public func foo(bar: Int = 0) {} }"),
            Example("func outer() { func inner(bar: Int = 0) {} }"),
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
            Example("class C { public func foo(bar: Int ↓= 0) {} }"),
            Example("struct S { public init(value: Int ↓= 42) {} }"),
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
