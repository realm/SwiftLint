import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct RedundantOptionalInitializationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_optional_initialization",
        name: "Redundant Optional Initialization",
        description: "Initializing an optional variable with nil is redundant",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var myVar: Int?"),
            Example("let myVar: Int? = nil"),
            Example("var myVar: Int? = 0"),
            Example("func foo(bar: Int? = 0) { }"),
            Example("var myVar: Optional<Int>"),
            Example("let myVar: Optional<Int> = nil"),
            Example("var myVar: Optional<Int> = 0"),
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
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            guard node.bindingSpecifier.tokenKind == .keyword(.var),
                  !node.modifiers.contains(keyword: .lazy) else {
                return
            }

            violations.append(contentsOf: node.bindings.compactMap(\.violationPosition))
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visitAny(_: Syntax) -> Syntax? { nil }

        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard node.bindingSpecifier.tokenKind == .keyword(.var),
                  !node.modifiers.contains(keyword: .lazy) else {
                return super.visit(node)
            }

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
