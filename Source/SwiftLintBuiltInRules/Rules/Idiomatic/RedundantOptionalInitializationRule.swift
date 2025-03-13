import SwiftSyntax
import SwiftLintCore

@SwiftSyntaxRule(explicitRewriter: true)
struct RedundantOptionalInitializationRule: Rule {
    @AutoConfigParser
    struct Configuration: SeverityBasedRuleConfiguration {
        typealias Parent = RedundantOptionalInitializationRule

        @ConfigurationElement(key: "severity")
        private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
        
        @ConfigurationElement(key: "excluded_attribute_names")
        private(set) var excludedAttributeNames: Set<String> = ["Parameter"]
    }
    
    var configuration = Configuration()

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
            Example("@Parameter static var someParameter: Bool? = nil"),  // Add example for @Parameter
            // properties with body should be ignored
            Example("""
            var foo: Int? {
              if bar != nil { }
              return 0
            }
            """),
            // properties with a closure call
            Example("""
            var foo: Int? = {
              if bar != nil { }
              return 0
            }()
            """),
            // lazy variables need to be initialized
            Example("lazy var test: Int? = nil"),
            // local variables
            Example("""
            func funcName() {
              var myVar: String?
            }
            """),
            Example("""
            func funcName() {
              let myVar: String? = nil
            }
            """),
        ],
        triggeringExamples: triggeringExamples,
        corrections: corrections
    )

    private static let triggeringExamples: [Example] = [
        Example("var myVar: Int?↓ = nil"),
        Example("var myVar: Optional<Int>↓ = nil"),
        Example("var myVar: Int?↓=nil"),
        Example("var myVar: Optional<Int>↓=nil\n)"),
        Example("""
              var myVar: String?↓ = nil {
                didSet { print("didSet") }
              }
              """),
        Example("""
            func funcName() {
                var myVar: String?↓ = nil
            }
            """),
    ]

    private static let corrections: [Example: Example] = [
        Example("var myVar: Int?↓ = nil"): Example("var myVar: Int?"),
        Example("var myVar: Optional<Int>↓ = nil"): Example("var myVar: Optional<Int>"),
        Example("var myVar: Int?↓=nil"): Example("var myVar: Int?"),
        Example("var myVar: Optional<Int>↓=nil"): Example("var myVar: Optional<Int>"),
        Example("class C {\n#if true\nvar myVar: Int?↓ = nil\n#endif\n}"):
            Example("class C {\n#if true\nvar myVar: Int?\n#endif\n}"),
        Example("""
            var myVar: Int?↓ = nil {
                didSet { }
            }
            """):
            Example("""
                var myVar: Int? {
                    didSet { }
                }
                """),
        Example("""
            var myVar: Int?↓=nil{
                didSet { }
            }
            """):
            Example("""
                var myVar: Int?{
                    didSet { }
                }
                """),
        Example("""
        func foo() {
            var myVar: String?↓ = nil, b: Int
        }
        """):
            Example("""
            func foo() {
                var myVar: String?, b: Int
            }
            """),
    ]
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

    final class Visitor: ViolationsSyntaxVisitor<Configuration> {
        override func visitPost(_ node: VariableDeclSyntax) {
            // Early return if no configuration or empty attributes to check
            guard !configuration.excludedAttributeNames.isEmpty else {
                // If no attributes to exclude, proceed with original logic
                if node.bindingSpecifier.tokenKind == .keyword(.var),
                   !node.modifiers.contains(keyword: .lazy) {
                    violations.append(contentsOf: node.bindings.compactMap(\.violationPosition))
                }
                return
            }

            guard node.bindingSpecifier.tokenKind == .keyword(.var),
                  !node.modifiers.contains(keyword: .lazy),
                  !RedundantOptionalInitializationRule.hasExcludedAttribute(node, excludedNames: configuration.excludedAttributeNames) else {
                return
            }

            violations.append(contentsOf: node.bindings.compactMap(\.violationPosition))
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<Configuration> {
        override func visitAny(_: Syntax) -> Syntax? { nil }

        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            // Early return if no configuration or empty attributes to check
            guard !configuration.excludedAttributeNames.isEmpty else {
                // If no attributes to exclude, proceed with original logic
                if node.bindingSpecifier.tokenKind == .keyword(.var),
                   !node.modifiers.contains(keyword: .lazy) {
                    return processViolations(for: node)
                }
                return super.visit(node)
            }

            guard node.bindingSpecifier.tokenKind == .keyword(.var),
                  !node.modifiers.contains(keyword: .lazy),
                  !RedundantOptionalInitializationRule.hasExcludedAttribute(node, excludedNames: configuration.excludedAttributeNames) else {
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
