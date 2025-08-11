import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ImplicitOptionalInitializationRule: Rule {
    var configuration = ImplicitOptionalInitializationConfiguration()

    static let description = RuleDescription(
        identifier: "implicit_optional_initialization",
        name: "Implicit Optional Initialization",
        description: "Optionals should be consistently initialized, either with `= nil` or without.",
        kind: .style,
        nonTriggeringExamples: ImplicitOptionalInitializationRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitOptionalInitializationRuleExamples.triggeringExamples,
        corrections: ImplicitOptionalInitializationRuleExamples.corrections,
        deprecatedAliases: ["redundant_optional_initialization"]
    )
}

private extension ImplicitOptionalInitializationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        var reason: String {
            switch configuration.style {
            case .always: "Optional should be implicitly initialized without nil"
            case .never: "Optional should be explicitly initialized to nil"
            }
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            guard let violationPosition = node.violationPosition(for: configuration.style) else { return }

            violations.append(ReasonedRuleViolation(position: violationPosition, reason: reason))
        }
    }
}

private extension ImplicitOptionalInitializationRule {
    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
            guard
                let violationPosition = node.violationPosition(for: configuration.style),
                !violationPosition.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            self.numberOfCorrections += 1

            return switch configuration.style {
            case .never:
                node
                    .with(
                        \.initializer,
                        InitializerClauseSyntax(
                            equal: .equalToken(
                                leadingTrivia: (node.typeAnnotation?.trailingTrivia.isEmpty ?? true)
                                ? .space
                                : Trivia(),
                                trailingTrivia: .space
                            ),
                            value: ExprSyntax(NilLiteralExprSyntax(nilKeyword: .keyword(.nil))),
                            trailingTrivia: node.typeAnnotation?.trailingTrivia ?? Trivia()
                        )
                    )
            case .always:
                node
                    .with(\.initializer, nil)
                    .with(
                        \.trailingTrivia,
                        node.accessorBlock == nil
                        ? node.initializer?.trailingTrivia ?? Trivia()
                        : node.trailingTrivia
                    )
            }
        }
    }
}

private extension PatternBindingSyntax {
    func violationPosition(
        for style: ImplicitOptionalInitializationConfiguration.Style
    ) -> AbsolutePosition? {
        guard
            let parent = parent?.parent?.as(VariableDeclSyntax.self),
            parent.bindingSpecifier.tokenKind == .keyword(.var),
            !parent.modifiers.contains(keyword: .lazy),
            let typeAnnotation,
            typeAnnotation.isOptionalType
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
            return positionAfterSkippingLeadingTrivia
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
