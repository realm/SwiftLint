import SwiftSyntax

// MARK: - SelfBindingRule

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct SelfBindingRule: Rule {
    var configuration = SelfBindingConfiguration()

    static let description = RuleDescription(
        identifier: "self_binding",
        name: "Self Binding",
        description: "Re-bind `self` to a consistent identifier name.",
        kind: .style,
        nonTriggeringExamples: [
            Example("if let self = self { return }"),
            Example("guard let self = self else { return }"),
            Example("if let this = this { return }"),
            Example("guard let this = this else { return }"),
            Example("if let this = self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let this = self else { return }", configuration: ["bind_identifier": "this"]),
        ],
        triggeringExamples: [
            Example("if let ↓`self` = self { return }"),
            Example("guard let ↓`self` = self else { return }"),
            Example("if let ↓this = self { return }"),
            Example("guard let ↓this = self else { return }"),
            Example("if let ↓self = self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let ↓self = self else { return }", configuration: ["bind_identifier": "this"]),
            Example("if let ↓self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let ↓self else { return }", configuration: ["bind_identifier": "this"]),
        ],
        corrections: [
            Example("if let ↓`self` = self { return }"):
                Example("if let self = self { return }"),
            Example("guard let ↓`self` = self else { return }"):
                Example("guard let self = self else { return }"),
            Example("if let ↓this = self { return }"):
                Example("if let self = self { return }"),
            Example("guard let ↓this = self else { return }"):
                Example("guard let self = self else { return }"),
            Example("if let ↓self = self { return }", configuration: ["bind_identifier": "this"]):
                Example("if let this = self { return }", configuration: ["bind_identifier": "this"]),
            Example("if let ↓self { return }", configuration: ["bind_identifier": "this"]):
                Example("if let this = self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let ↓self else { return }", configuration: ["bind_identifier": "this"]):
                Example("guard let this = self else { return }", configuration: ["bind_identifier": "this"]),
        ]
    )
}

private extension SelfBindingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            if let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
               identifierPattern.identifier.text != configuration.bindIdentifier {
                var hasViolation = false
                if let initializerIdentifier = node.initializer?.value.as(DeclReferenceExprSyntax.self) {
                    hasViolation = initializerIdentifier.baseName.text == "self"
                } else if node.initializer == nil {
                    hasViolation = identifierPattern.identifier.text == "self" && configuration.bindIdentifier != "self"
                }

                if hasViolation {
                    violations.append(
                        ReasonedRuleViolation(
                            position: identifierPattern.positionAfterSkippingLeadingTrivia,
                            reason: "`self` should always be re-bound to `\(configuration.bindIdentifier)`"
                        )
                    )
                }
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
            guard let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
                  identifierPattern.identifier.text != configuration.bindIdentifier else {
                return super.visit(node)
            }

            if let initializerIdentifier = node.initializer?.value.as(DeclReferenceExprSyntax.self),
               initializerIdentifier.baseName.text == "self" {
                correctionPositions.append(identifierPattern.positionAfterSkippingLeadingTrivia)

                let newPattern = PatternSyntax(
                    identifierPattern
                        .with(\.identifier, identifierPattern.identifier
                            .with(\.tokenKind, .identifier(configuration.bindIdentifier)))
                )

                return super.visit(node.with(\.pattern, newPattern))
            }
            if node.initializer == nil,
                      identifierPattern.identifier.text == "self",
                      configuration.bindIdentifier != "self" {
                correctionPositions.append(identifierPattern.positionAfterSkippingLeadingTrivia)

                let newPattern = PatternSyntax(
                    identifierPattern
                        .with(\.identifier, identifierPattern.identifier
                            .with(\.tokenKind, .identifier(configuration.bindIdentifier)))
                )

                let newInitializer = InitializerClauseSyntax(
                    value: DeclReferenceExprSyntax(
                        baseName: .keyword(
                            .`self`,
                            leadingTrivia: .space,
                            trailingTrivia: identifierPattern.trailingTrivia
                        )
                    )
                )

                let newNode = node
                    .with(\.pattern, newPattern)
                    .with(\.initializer, newInitializer)
                return super.visit(newNode)
            }
            return super.visit(node)
        }
    }
}
