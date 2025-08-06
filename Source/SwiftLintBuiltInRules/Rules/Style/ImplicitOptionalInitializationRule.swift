import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ImplicitOptionalInitializationRule: Rule {
    var configuration = ImplicitOptionalInitConfiguration()

    static let description = RuleDescription(
        identifier: "implicit_optional_initialization",
        name: "Implicit Optional Initialization",
        description: "Optionals should be consistently initialised",
        kind: .style,
        nonTriggeringExamples: ImplicitOptionalInitRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitOptionalInitRuleExamples.triggeringExamples,
        corrections: ImplicitOptionalInitRuleExamples.corrections,
        deprecatedAliases: ["redundant_optional_initialization"]
    )
}

private extension ImplicitOptionalInitializationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            violations.append(
                contentsOf: node.violationPositions(for: configuration.style).map {
                    ReasonedRuleViolation(position: $0, reason: reason)
                })
        }

        var reason: String {
            let recommendation =
                switch configuration.style {
                case .always: "explicitly initialized to nil"
                case .never: "implicitly initialized without nil"
                }

            return "Optionals should be \(recommendation) in variable declarations"
        }
    }
}

private extension ImplicitOptionalInitializationRule {
    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            let violationPositions = node.violationPositions(for: configuration.style)
            guard !violationPositions.isEmpty else { return super.visit(node) }

            numberOfCorrections +=
                violationPositions.filter {
                    !$0.isContainedIn(
                        regions: disabledRegions, locationConverter: locationConverter)
                }.count

            return super.visit(
                node.with(
                    \.bindings,
                    PatternBindingListSyntax(
                        node.bindings.map { binding in
                            guard
                                let violationPosition = binding.violationPosition(
                                    for: configuration.style),
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
                                        \.typeAnnotation,
                                        binding.typeAnnotation?.with(\.trailingTrivia, Trivia())
                                    )
                                    .with(
                                        \.initializer,
                                        InitializerClauseSyntax(
                                            equal: .equalToken(
                                                leadingTrivia: .space, trailingTrivia: .space),
                                            value: ExprSyntax(
                                                NilLiteralExprSyntax(nilKeyword: .keyword(.nil))),
                                            trailingTrivia: binding.typeAnnotation?.trailingTrivia
                                                ?? Trivia()
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
    ) -> [AbsolutePosition] {
        guard
            bindingSpecifier.tokenKind == .keyword(.var),
            !modifiers.contains(keyword: .lazy)
        else { return [] }

        return bindings.compactMap { $0.violationPosition(for: style) }
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
                if accessors.contains(where: {
                    $0.accessorSpecifier.tokenKind != .keyword(.willSet)
                        && $0.accessorSpecifier.tokenKind != .keyword(.didSet)
                }) {  // we have more than willSet or didSet
                    return nil
                }
            } else {  // code block, i.e. getter
                return nil
            }
        }

        if (style == .never && !initializer.isNil) || (style == .always && initializer.isNil) {
            return pattern.endPositionBeforeTrailingTrivia
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
