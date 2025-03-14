import SwiftSyntax
import SwiftLintCore

// MARK: - Configuration
@AutoConfigParser
struct RedundantOptionalInitializationConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = RedundantOptionalInitializationRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded_attribute_names")
    private(set) var excludedAttributeNames: Set<String> = ["Parameter"]
}

@SwiftSyntaxRule(explicitRewriter: true)
struct RedundantOptionalInitializationRule: Rule {
    var configuration = RedundantOptionalInitializationConfiguration()

    static let description = RuleDescription(
        identifier: "redundant_optional_initialization",
        name: "Redundant Optional Initialization",
        description: """
            Initializing an optional variable with nil is redundant.

            Configuration:
            - severity: warning | error (default: warning)
            - excluded_attribute_names: array of attribute names to exclude (default: ["Parameter"])

            Example configuration in yaml:
            ```yaml
            redundant_optional_initialization:
              severity: error
              excluded_attribute_names: ["Parameter"]
            ```
            """,
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var myVar: Int?"),
            Example("let myVar: Int? = nil"),
            Example("var myVar: Int? = 0"),
            Example("func foo(bar: Int? = 0) { }"),
            Example("var myVar: Optional<Int>"),
            Example("let myVar: Optional<Int> = nil"),
            Example("var myVar: Optional<Int> = 0"),
            Example("@Parameter static var someParameter: Bool? = nil"),
            Example("var foo: Int? {\n  if bar != nil { }\n  return 0\n}"),
            Example("var foo: Int? = {\n  if bar != nil { }\n  return 0\n}()"),
            Example("lazy var test: Int? = nil"),
            Example("func funcName() {\n  var myVar: String?\n}"),
            Example("func funcName() {\n  let myVar: String? = nil\n}")
        ],
        triggeringExamples: [
            Example("var myVar: Int?↓ = nil"),
            Example("var myVar: Optional<Int>↓ = nil"),
            Example("var myVar: Int?↓=nil"),
            Example("var myVar: Optional<Int>↓=nil\n)"),
            Example("var myVar: String?↓ = nil {\n  didSet { print(\"didSet\") }\n}"),
            Example("func funcName() {\n    var myVar: String?↓ = nil\n}")
        ],
        corrections: [
            Example("var myVar: Int?↓ = nil"): Example("var myVar: Int?"),
            Example("var myVar: Optional<Int>↓ = nil"): Example("var myVar: Optional<Int>"),
            Example("var myVar: Int?↓=nil"): Example("var myVar: Int?"),
            Example("var myVar: Optional<Int>↓=nil"): Example("var myVar: Optional<Int>"),
            Example("class C {\n#if true\nvar myVar: Int?↓ = nil\n#endif\n}"):
                Example("class C {\n#if true\nvar myVar: Int?\n#endif\n}"),
            Example("var myVar: Int?↓ = nil {\n    didSet { }\n}"):
                Example("var myVar: Int? {\n    didSet { }\n}"),
            Example("var myVar: Int?↓=nil{\n    didSet { }\n}"):
                Example("var myVar: Int?{\n    didSet { }\n}"),
            Example("func foo() {\n    var myVar: String?↓ = nil, b: Int\n}"):
                Example("func foo() {\n    var myVar: String?, b: Int\n}")
        ]
    )
}

private extension RedundantOptionalInitializationRule {
    // Helper function to check for excluded attributes
    static func hasExcludedAttribute(_ node: VariableDeclSyntax, excludedNames: Set<String>) -> Bool {
        guard !excludedNames.isEmpty else { return false }
        
        return node.attributes.contains { attr -> Bool in
            guard let identAttr = attr.as(AttributeSyntax.self),
                let nameIdentifier = identAttr.attributeName.as(IdentifierTypeSyntax.self),
                !nameIdentifier.name.text.isEmpty else {
                return false
            }
            return excludedNames.contains(nameIdentifier.name.text)
        }
    }

    final class Visitor: ViolationsSyntaxVisitor<RedundantOptionalInitializationConfiguration> {
        override func visitPost(_ node: VariableDeclSyntax) {
            guard node.bindingSpecifier.tokenKind == .keyword(.var),
                !node.modifiers.contains(keyword: .lazy),
                !RedundantOptionalInitializationRule.hasExcludedAttribute(
                    node,
                    excludedNames: configuration.excludedAttributeNames
                ) else {
                return
            }

            violations.append(contentsOf: node.bindings.compactMap(\.violationPosition))
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<RedundantOptionalInitializationConfiguration> {
        override func visitAny(_: Syntax) -> Syntax? { nil }

        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard node.bindingSpecifier.tokenKind == .keyword(.var),
                !node.modifiers.contains(keyword: .lazy),
                !RedundantOptionalInitializationRule.hasExcludedAttribute(
                    node,
                    excludedNames: configuration.excludedAttributeNames
                ) else {
                return super.visit(node)
            }

            return processViolations(for: node)
        }

        private func processViolations(for node: VariableDeclSyntax) -> DeclSyntax {
            let violations = node.bindings
                .compactMap { binding in
                    binding.violationPosition.map { ($0, binding) }
                }
                .filter { position, _ in
                    !position.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
                }

            guard violations.isNotEmpty else {
                return super.visit(node)
            }

            correctionPositions.append(contentsOf: violations.map(\.0))

            let violatingBindings = violations.map(\.1)
            let newBindings = PatternBindingListSyntax(node.bindings.map { binding in
                guard violatingBindings.contains(binding) else {
                    return binding
                }
                let newBinding = binding.with(\.initializer, nil)
                if newBinding.accessorBlock != nil {
                    return newBinding
                }
                if binding.trailingComma != nil {
                    return newBinding.with(\.typeAnnotation, binding.typeAnnotation?.with(\.trailingTrivia, Trivia()))
                }
                return newBinding.with(\.trailingTrivia, binding.initializer?.trailingTrivia ?? Trivia())
            })

            return super.visit(node.with(\.bindings, newBindings))
        }
    }
}

private extension PatternBindingSyntax {
    var violationPosition: AbsolutePosition? {
        guard let initializer,
            let type = typeAnnotation,
            initializer.isInitializingToNil,
            type.isOptionalType else {
            return nil
        }

        return type.endPositionBeforeTrailingTrivia
    }
}

private extension InitializerClauseSyntax {
    var isInitializingToNil: Bool {
        value.is(NilLiteralExprSyntax.self)
    }
}

private extension TypeAnnotationSyntax {
    var isOptionalType: Bool {
        if type.is(OptionalTypeSyntax.self) {
            return true
        }

        if let type = type.as(IdentifierTypeSyntax.self), let genericClause = type.genericArgumentClause {
            return genericClause.arguments.count == 1 && type.name.text == "Optional"
        }

        return false
    }
}
