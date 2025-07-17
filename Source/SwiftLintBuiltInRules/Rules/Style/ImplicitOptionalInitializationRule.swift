import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ImplicitOptionalInitializationRule: Rule {
  var configuration = ImplicitOptionalInitializationConfiguration()

  static let description = RuleDescription(
    identifier: "implicit_optional_initialization",
    name: "Implicit Optional Initialization",
    description: "Enforce implicit initialization of optional variables (always or never)",
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

      // never style
      Example("var myVar: Int? = nil", configuration: ["style": "never"]),
      Example("var myVar: Optional<Int> = nil", configuration: ["style": "never"]),
      Example(
        """
        var myVar: String? = nil {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "never"]),
      Example(
        """
        func funcName() {
            var myVar: String? = nil
        }
        """, configuration: ["style": "never"]),

      // always style
      Example("var myVar: Int?", configuration: ["style": "always"]),
      Example("var myVar: Optional<Int>", configuration: ["style": "always"]),
      Example(
        """
        var myVar: String? {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "always"]),
      Example(
        """
        func funcName() {
          var myVar: String?
        }
        """, configuration: ["style": "always"]),
    ],
    triggeringExamples: [
      // never style
      Example("var myVar: Int?↓ ", configuration: ["style": "never"]),
      Example("var myVar: Optional<Int>↓ ", configuration: ["style": "never"]),
      Example("var myVar: Int?↓, myOtherVar = true", configuration: ["style": "never"]),
      Example(
        """
        var myVar: String?↓ {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "never"]),
      Example(
        """
        func funcName() {
          var myVar: String?↓
        }
        """, configuration: ["style": "never"]
      ),

      // always style
      Example("var myVar: Int?↓ = nil", configuration: ["style": "always"]),
      Example("var myVar: Optional<Int>↓ = nil", configuration: ["style": "always"]),
      Example("var myVar: Int?↓ = nil, myOtherVar = true", configuration: ["style": "always"]),
      Example(
        """
        var myVar: String?↓ = nil {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "always"]),
      Example(
        """
        func funcName() {
            var myVar: String?↓ = nil
        }
        """, configuration: ["style": "always"]),
    ],
    corrections: [
      // never style
      Example("var myVar: Int?↓ ", configuration: ["style": "never"]):
        Example("var myVar: Int? = nil "),
      Example("var myVar: Optional<Int>↓ ", configuration: ["style": "never"]):
        Example("var myVar: Optional<Int> = nil "),
      Example(
        """
        var myVar: String?↓ {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "never"]):
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
        """, configuration: ["style": "never"]
      ): Example(
        """
        func funcName() {
          var myVar: String? = nil
        }
        """),

      Example("var myVar: Int?↓ = nil", configuration: ["style": "always"]):
        Example("var myVar: Int?"),
      Example("var myVar: Optional<Int>↓ = nil", configuration: ["style": "always"]):
        Example("var myVar: Optional<Int>"),
      Example(
        """
        var myVar: String?↓ = nil {
          didSet { print("didSet") }
        }
        """, configuration: ["style": "always"]):
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
        """, configuration: ["style": "always"]):
        Example(
          """
          func funcName() {
              var myVar: String?
          }
          """),
    ]
  )
}

extension ImplicitOptionalInitializationRule {
  fileprivate final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard let violationPositions = node.violationPositions(for: configuration.style) else {
        return
      }

      violations.append(contentsOf: violationPositions)
    }
  }
}

extension VariableDeclSyntax {
  fileprivate func violationPositions(
    for style: ImplicitOptionalInitializationConfiguration.Style
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
  fileprivate func violationPosition(
    for style: ImplicitOptionalInitializationConfiguration.Style
  ) -> AbsolutePosition? {
    guard
      let typeAnnotation: TypeAnnotationSyntax, typeAnnotation.isOptionalType
    else { return nil }

    if (style == .never && !initializer.isNil) || (style == .always && initializer.isNil) {
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
      let genericClause = type.genericArgumentClause {
      return genericClause.arguments.count == 1 && type.name.text == "Optional"
    }

    return false
  }
}

extension ImplicitOptionalInitializationRule {
  fileprivate final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
    override func visitAny(_: Syntax) -> Syntax? { nil }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
      guard let violationPositions = node.violationPositions(for: configuration.style) else {
        return super.visit(node)
      }

      numberOfCorrections +=
        violationPositions.filter {
          !$0.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
        }.count

      return super.visit(
        node.with(
          \.bindings,
          PatternBindingListSyntax(
            node.bindings.map { binding in
              guard let violationPosition = binding.violationPosition(for: configuration.style),
                !violationPosition.isContainedIn(
                  regions: disabledRegions, locationConverter: locationConverter)
              else {
                return binding
              }

              switch configuration.style {
              case .never:
                return
                  binding
                  .with(
                    \.typeAnnotation, binding.typeAnnotation?.with(\.trailingTrivia, Trivia())
                  )
                  .with(
                    \.initializer,
                    InitializerClauseSyntax(
                      equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                      value: ExprSyntax(NilLiteralExprSyntax(nilKeyword: .keyword(.nil))),
                      trailingTrivia: binding.typeAnnotation?.trailingTrivia ?? Trivia()
                    ))
              case .always:
                return
                  binding
                  .with(\.initializer, nil)
                  .with(
                    \.trailingTrivia,
                    binding.accessorBlock == nil
                      ? binding.initializer?.trailingTrivia ?? Trivia()
                      : binding.trailingTrivia)
              }
            }))
      )
    }
  }
}
