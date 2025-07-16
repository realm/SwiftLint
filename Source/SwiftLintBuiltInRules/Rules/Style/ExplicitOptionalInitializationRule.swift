import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ExplicitOptionalInitializationRule: Rule {
  var configuration = ExplicitOptionalInitializationConfiguration()

  static let description = RuleDescription(
    identifier: "explicit_optional_initialization",
    name: "Explicit Optional Initialization",
    description:
      "Detects optional variable declarations that either explicitly initialize to nil or omit the initializer, depending on the configured style (always or never)",
    kind: .style,
    nonTriggeringExamples: [
      Example("var a: Optional<Int> = nil", configuration: ["style": "always"]),
      Example("var b: Int? = nil", configuration: ["style": "always"]),
      Example("var b: Optional<Int>", configuration: ["style": "never"]),
      Example("var a: Int?", configuration: ["style": "never"]),
    ],
    triggeringExamples: [
      Example("var a: Optional<Int>↓", configuration: ["style": "always"]),
      Example("var a: Int?↓", configuration: ["style": "always"]),
      Example("var b: Optional<Int>↓ = nil", configuration: ["style": "never"]),
      Example("var b: Int?↓ = nil", configuration: ["style": "never"]),
    ],
    corrections: [
      :
      // Example("var a: Optional<Int>↓", configuration: ["style": "always"]):
      //   Example("var a: Optional<Int> = nil"),
      // Example("var a: Int?↓", configuration: ["style": "always"]): Example("var a: Int? = nil"),
      // Example("var b: Optional<Int>↓ = nil", configuration: ["style": "never"]):
      //   Example("var b: Optional<Int>"),
      // Example("var b: Int?↓ = nil", configuration: ["style": "never"]): Example("var b: Int?"),
    ]
  )
}

extension ExplicitOptionalInitializationRule {
  fileprivate final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard
        node.bindingSpecifier.tokenKind == .keyword(.var),
        !node.modifiers.contains(keyword: .lazy)
      else { return }

      for binding in node.bindings {
        if let violation = binding.violation(for: configuration.style) {
          violations.append(violation)
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
    override func visitAny(_: Syntax) -> Syntax? { nil }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
      guard
        node.bindingSpecifier.tokenKind == .keyword(.var),
        !node.modifiers.contains(keyword: .lazy)
      else { return super.visit(node) }

      let updatedBindings = PatternBindingListSyntax(
        node.bindings.map {
          guard $0.violation(for: configuration.style) != nil else { return $0 }

          numberOfCorrections += 1

          var binding = $0
          switch configuration.style {
          case .always:
            binding.trailingTrivia = Trivia()
            binding.initializer = InitializerClauseSyntax(
              equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
              value: ExprSyntax(NilLiteralExprSyntax(nilKeyword: .keyword(.nil)))
            )
          case .never:
            binding.initializer = nil
            binding.trailingTrivia = Trivia()
          }
          return binding
        })

      guard updatedBindings != node.bindings else { return super.visit(node) }

      return super.visit(node.with(\.bindings, updatedBindings))
    }
  }
}

extension PatternBindingSyntax {
  fileprivate func violation(for style: ExplicitOptionalInitializationConfiguration.Style)
    -> AbsolutePosition?
  {
    guard
      let typeAnnotation, typeAnnotation.isOptionalType,
      (style == .always && initializer == nil)
        || (style == .never && initializer != nil)
    else { return nil }

    return typeAnnotation.type.endPositionBeforeTrailingTrivia
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
