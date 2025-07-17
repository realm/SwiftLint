import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ExplicitOptionalInitializationRule: Rule {
  var configuration = ExplicitOptionalInitializationConfiguration()

  static let description = RuleDescription(
    identifier: "explicit_optional_initialization",
    name: "Explicit Optional Initialization",
    description:
      "Always explicitly initialize an optional variable with nil (style: always) or never (style: never)",
    kind: .style,
    nonTriggeringExamples: [
      Example(  // properties with body should be ignored
        """
        var foo: Int? {
          if bar != nil { }
          return 0
        }
        """),
      Example(  // properties with a closure call
        """
        var foo: Int? = {
          if bar != nil { }
          return 0
        }()
        """
      ),
      Example("lazy var test: Int? = nil"),  // lazy variables need to be initialized
      Example("let myVar: String? = nil"),  // let variables can be initialized with nil

      // always style
      Example("var myVar: Int? = nil", configuration: ["style": "always"]),
      Example("var myVar: Optional<Int> = nil", configuration: ["style": "always"]),
      Example(
        """
        var myVar: String? = nil {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "always"]),
      Example(
        """
        func funcName() {
            var myVar: String? = nil
        }
        """, configuration: ["style": "always"]),

      // never style
      Example("var myVar: Int?", configuration: ["style": "never"]),
      Example("var myVar: Optional<Int>", configuration: ["style": "never"]),
      Example(
        """
        var myVar: String? {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "never"]),
      Example(
        """
        func funcName() {
          var myVar: String?
        }
        """, configuration: ["style": "never"]),
    ],
    triggeringExamples: [
      // always style
      Example("var myVar: Int?↓ ", configuration: ["style": "always"]),
      Example("var myVar: Optional<Int>↓ ", configuration: ["style": "always"]),
      Example(
        """
        var myVar: String?↓ {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "always"]),
      Example(
        """
        func funcName() {
          var myVar: String?↓
        }
        """, configuration: ["style": "always"]
      ),

      // never style
      Example("var myVar: Int?↓ = nil", configuration: ["style": "never"]),
      Example("var myVar: Optional<Int>↓ = nil", configuration: ["style": "never"]),
      Example(
        """
        var myVar: String?↓ = nil {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "never"]),
      Example(
        """
        func funcName() {
            var myVar: String?↓ = nil
        }
        """, configuration: ["style": "never"]),
    ],
    corrections: [
      // always style
      Example("var myVar: Int?↓ ", configuration: ["style": "always"]):
        Example("var myVar: Int? = nil"),
      Example("var myVar: Optional<Int>↓ ", configuration: ["style": "always"]):
        Example("var myVar: Optional<Int> = nil"),
      Example(
        """
        var myVar: String?↓ {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "always"]
      ).focused():
        Example(
          """
          var myVar: String? = nil {
            didSet { print("didSet") }
          }
          """),
      Example(
        """
        func funcName() {
          var myVar: String?↓
        }
        """, configuration: ["style": "always"]
      ): Example(
        """
        func funcName() {
          var myVar: String? = nil
        }
        """
      ),

      Example("var myVar: Int?↓ = nil", configuration: ["style": "never"]):
        Example("var myVar: Int?"),
      Example("var myVar: Optional<Int>↓ = nil", configuration: ["style": "never"]):
        Example("var myVar: Optional<Int>"),
      Example(
        """
        var myVar: String?↓ = nil {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "never"]):
        Example(
          """
          var myVar: String? {
            didSet { print("didSet") }
          }
          """),
      Example(
        """
        func funcName() {
            var myVar: String?↓ = nil
        }
        """, configuration: ["style": "never"]):
        Example(
          """
          func funcName() {
              var myVar: String?
          }
          """),
    ]
  )
}

extension ExplicitOptionalInitializationRule {
  fileprivate final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard let violationPositions = node.violationPositions(for: configuration.style) else {
        return
      }

      violations.append(contentsOf: violationPositions)
    }
  }

  fileprivate final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
    override func visitAny(_: Syntax) -> Syntax? { nil }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
      guard let violationPositions = node.violationPositions(for: configuration.style) else {
        return super.visit(node)
      }

      numberOfCorrections += violationPositions.count

      return super.visit(
        node
          .with(
            \.bindings,
            PatternBindingListSyntax(
              node.bindings.map { binding in
                guard binding.violationPosition(for: configuration.style) != nil else {
                  return binding
                }

                print(configuration.style, binding)

                switch configuration.style {
                case .always:
                  return
                    binding
                    // .with(
                    //   \.typeAnnotation, binding.typeAnnotation?.with(\.trailingTrivia, Trivia())
                    // )
                    .with(
                      \.initializer,
                      InitializerClauseSyntax(
                        equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                        value: ExprSyntax(NilLiteralExprSyntax(nilKeyword: .keyword(.nil))),
                        trailingTrivia: binding.typeAnnotation?.trailingTrivia ?? Trivia()
                      ))
                case .never:
                  return
                    binding
                    .with(\.initializer, nil)
                    .with(
                      \.typeAnnotation,
                      binding.trailingComma != nil
                        ? binding.typeAnnotation?.with(\.trailingTrivia, Trivia())
                        : binding.typeAnnotation
                    )
                    .with(\.trailingTrivia, binding.initializer?.trailingTrivia ?? Trivia())
                }
              })))
    }
  }
}

extension VariableDeclSyntax {
  fileprivate func violationPositions(
    for style: ExplicitOptionalInitializationConfiguration.Style
  ) -> [AbsolutePosition]? {
    guard
      bindingSpecifier.tokenKind == .keyword(.var),
      !modifiers.contains(keyword: .lazy)
    else { return nil }

    let bindings = bindings.compactMap { $0.violationPosition(for: style) }

    return bindings.isEmpty ? nil : bindings
  }
}

extension PatternBindingSyntax {
  fileprivate func violationPosition(for style: ExplicitOptionalInitializationConfiguration.Style)
    -> AbsolutePosition?
  {
    guard
      let typeAnnotation: TypeAnnotationSyntax, typeAnnotation.isOptionalType
    else { return nil }

    if (style == .always && !initializer.isNil) || (style == .never && initializer.isNil) {
      return typeAnnotation.endPositionBeforeTrailingTrivia
    }

    return nil
  }
}

extension InitializerClauseSyntax? {
  fileprivate var isNil: Bool {
    self?.value.is(NilLiteralExprSyntax.self) ?? false
  }
}

extension TypeAnnotationSyntax {
  fileprivate var isOptionalType: Bool {
    if type.is(OptionalTypeSyntax.self) { return true }

    if let type = type.as(IdentifierTypeSyntax.self),
      let genericClause = type.genericArgumentClause
    {
      return genericClause.arguments.count == 1 && type.name.text == "Optional"
    }

    return false
  }
}
