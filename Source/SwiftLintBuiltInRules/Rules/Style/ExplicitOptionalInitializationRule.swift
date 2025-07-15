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
      Example("var b: Int? = nil", configuration: ["style": "always"]),
      Example("var a: Int?", configuration: ["style": "never"]),
    ],
    triggeringExamples: [
      Example("var a: Int?↓", configuration: ["style": "always"]),
      Example("var b: Int? = ↓nil", configuration: ["style": "never"]),
    ],
    corrections: [
      Example("var a: Int?↓", configuration: ["style": "always"]): Example("var a: Int? = nil"),
      Example("var b: Int? = ↓nil", configuration: ["style": "never"]): Example("var b: Int?"),
    ]
  )
}

extension ExplicitOptionalInitializationRule {
  fileprivate final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard node.bindingSpecifier.tokenKind == .keyword(.var),
        !node.modifiers.contains(keyword: .lazy)
      else {
        return
      }

      for binding in node.bindings {
        if let position = binding.violationPosition(for: configuration.style) {
          violations.append(position)
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
    override func visitAny(_: Syntax) -> Syntax? { nil }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
      guard node.bindingSpecifier.tokenKind == .keyword(.var),
        !node.modifiers.contains(keyword: .lazy)
      else {
        return super.visit(node)
      }

      let violations = node.bindings
        .compactMap { binding in
          binding.violationPosition(for: configuration.style).map { ($0, binding) }
        }
        .filter { position, _ in
          !position.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
        }

      guard violations.isNotEmpty else {
        return super.visit(node)
      }

      numberOfCorrections += violations.count
      let violatingBindings = violations.map(\.1)

      let newBindings = PatternBindingListSyntax(
        node.bindings.map { binding in
          guard violatingBindings.contains(binding) else {
            return binding
          }

          switch configuration.style {
          case .never:
            return
              binding
              .with(\.initializer, nil)
              .with(\.trailingTrivia, Trivia())

          case .always:
            guard binding.initializer == nil else { return binding }

            let nilExpr = ExprSyntax(NilLiteralExprSyntax(nilKeyword: .keyword(.nil)))
            let initializer = InitializerClauseSyntax(
              equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
              value: nilExpr
            )
            return binding.with(\.initializer, initializer)
          }
        }
      )

      return super.visit(node.with(\.bindings, newBindings))
    }
  }
}

extension PatternBindingSyntax {
  fileprivate func violationPosition(
    for style: ExplicitOptionalInitializationConfiguration.Style
  ) -> AbsolutePosition? {
    switch style {
    case .never:
      guard let initializer,
        let type = typeAnnotation,
        initializer.isInitializingToNil,
        type.isOptionalType
      else {
        return nil
      }
      return initializer.value.positionAfterSkippingLeadingTrivia

    case .always:
      guard initializer == nil,
        let type = typeAnnotation,
        type.isOptionalType
      else {
        return nil
      }
      if let optionalType = type.type.as(OptionalTypeSyntax.self) {
        return optionalType.questionMark.position
      }
      return nil
    }
  }
}

extension InitializerClauseSyntax {
  fileprivate var isInitializingToNil: Bool {
    value.is(NilLiteralExprSyntax.self)
  }
}

extension TypeAnnotationSyntax {
  fileprivate var isOptionalType: Bool {
    if type.is(OptionalTypeSyntax.self) {
      return true
    }

    if let type = type.as(IdentifierTypeSyntax.self),
      let genericClause = type.genericArgumentClause
    {
      return genericClause.arguments.count == 1 && type.name.text == "Optional"
    }

    return false
  }
}
