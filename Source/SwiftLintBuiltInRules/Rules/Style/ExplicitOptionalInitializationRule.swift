import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ExplicitOptionalInitializationRule: Rule {
  var configuration = ExplicitOptionalInitializationConfiguration()

  static let description = RuleDescription(
    identifier: "explicit_optional_initialization",
    name: "Explicit Optional Initialization",
    description:
      "Detects optional variable declarations that either explicitly initialize to nil or omit the initializer, depending on the configured style (always or never).",
    kind: .style
  )  // TODO: figure out how to add triggering examples per configuration
}

extension ExplicitOptionalInitializationRule {
  fileprivate final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard node.bindingSpecifier.tokenKind == .keyword(.var),
        !node.modifiers.contains(keyword: .lazy)
      else {
        return
      }

      violations.append(
        contentsOf: node.bindings.compactMap {
          $0.violationPosition(for: configuration.enforcement)
        })
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
          binding.violationPosition(for: configuration.enforcement).map { ($0, binding) }
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
          let newBinding = binding.with(\.initializer, nil)
          if newBinding.accessorBlock != nil {
            return newBinding
          }
          if binding.trailingComma != nil {
            return newBinding.with(
              \.typeAnnotation, binding.typeAnnotation?.with(\.trailingTrivia, Trivia()))
          }
          return newBinding.with(\.trailingTrivia, binding.initializer?.trailingTrivia ?? Trivia())
        })

      return super.visit(node.with(\.bindings, newBindings))
    }
  }
}

extension PatternBindingSyntax {
  fileprivate func violationPosition(
    for enforcement: ExplicitOptionalInitializationConfiguration.Enforcement
  ) -> AbsolutePosition? {
    switch enforcement {
    case .never:
      guard let initializer,
        let type = typeAnnotation,
        initializer.isInitializingToNil,
        type.isOptionalType
      else {
        return nil
      }
      return type.endPositionBeforeTrailingTrivia

    case .always:
      guard initializer == nil,
        let type = typeAnnotation,
        type.isOptionalType
      else {
        return nil
      }
      return type.endPositionBeforeTrailingTrivia
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

    if let type = type.as(IdentifierTypeSyntax.self), let genericClause = type.genericArgumentClause
    {
      return genericClause.arguments.count == 1 && type.name.text == "Optional"
    }

    return false
  }
}
