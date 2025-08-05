import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ImplicitOptionalInitializationRule: Rule {
  var configuration = ImplicitOptionalInitConfiguration()

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
      Example("let myVar: String? = nil"),  // let variables need to be initialized
      Example("var myVar: Int? { nil }"),  // computed properties should be ignored
      Example("var x: Int? = 1"),  // initialized with a value

      // never style
      Example("private var myVar: Int? = nil", configuration: ["style": "never"]),
      Example("var myVar: Optional<Int> = nil", configuration: ["style": "never"]),
      Example("var myVar: Int? { nil }, myOtherVar: Int? = nil", configuration: ["style": "never"]),
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
      Example("public var myVar: Int?", configuration: ["style": "always"]),
      Example("var myVar: Optional<Int>", configuration: ["style": "always"]),
      Example("var myVar: Int? { nil }, myOtherVar: Int?", configuration: ["style": "always"]),
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
      Example("var myVar: Int? = nil, myOtherVar: Int?↓ ", configuration: ["style": "never"]),
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
      Example("var myVar: Int?, myOtherVar: Int?↓ = nil", configuration: ["style": "always"]),
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
    ],
    deprecatedAliases: ["redundant_optional_initialization"]
  )
}

private extension ImplicitOptionalInitializationRule {
  final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard let violationPositions = node.violationPositions(for: configuration.style) else {
        return
      }

      violations.append(contentsOf: violationPositions)
    }
  }
}

private extension ImplicitOptionalInitializationRule {
  final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
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

private extension VariableDeclSyntax {
  func violationPositions(
    for style: ImplicitOptionalInitConfiguration.Style
  ) -> [AbsolutePosition]? {
    guard
      bindingSpecifier.tokenKind == .keyword(.var),
      !modifiers.contains(keyword: .lazy)
    else { return nil }

    let bindings = bindings.compactMap { $0.violationPosition(for: style) }

    return bindings.isEmpty ? nil : bindings
  }
}

private extension PatternBindingSyntax {
  func violationPosition(
    for style: ImplicitOptionalInitConfiguration.Style
  ) -> AbsolutePosition? {
    guard
      let typeAnnotation, typeAnnotation.isOptionalType
    else { return nil }

    // ignore properties with accessors unless they have only willSet or didSet
    if let accessorBlock {
      if let accessors = accessorBlock.accessors.as(AccessorDeclListSyntax.self) {
        if accessors.allSatisfy({
          $0.accessorSpecifier.tokenKind != .keyword(.willSet)
            && $0.accessorSpecifier.tokenKind != .keyword(.didSet)
        }) {  // we have not only willSet or didSet
          return nil
        }
      } else {  // we have not only willSet or didSet
        return nil
      }
    }

    if (style == .never && !initializer.isNil) || (style == .always && initializer.isNil) {
      return typeAnnotation.endPositionBeforeTrailingTrivia
    }

    return nil
  }
}

private extension InitializerClauseSyntax? {
  var isNil: Bool {
    self?.value.is(NilLiteralExprSyntax.self) ?? false
  }
}

private extension TypeAnnotationSyntax {
  var isOptionalType: Bool {
    if type.is(OptionalTypeSyntax.self) { return true }

    if let type = type.as(IdentifierTypeSyntax.self),
      let genericClause = type.genericArgumentClause {
      return genericClause.arguments.count == 1 && type.name.text == "Optional"
    }

    return false
  }
}
