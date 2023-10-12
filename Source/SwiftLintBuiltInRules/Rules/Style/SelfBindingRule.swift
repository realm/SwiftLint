import SwiftSyntax

// MARK: - SelfBindingRule

@SwiftSyntaxRule(needsConfiguration: true)
struct SelfBindingRule: SwiftSyntaxCorrectableRule, OptInRule {
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
            Example("guard let this = self else { return }", configuration: ["bind_identifier": "this"])
        ],
        triggeringExamples: [
            Example("if let ↓`self` = self { return }"),
            Example("guard let ↓`self` = self else { return }"),
            Example("if let ↓this = self { return }"),
            Example("guard let ↓this = self else { return }"),
            Example("if let ↓self = self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let ↓self = self else { return }", configuration: ["bind_identifier": "this"]),
            Example("if let ↓self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let ↓self else { return }", configuration: ["bind_identifier": "this"])
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
                Example("guard let this = self else { return }", configuration: ["bind_identifier": "this"])
        ]
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            bindIdentifier: configuration.bindIdentifier,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension SelfBindingRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: ConfigurationType

        init(configuration: ConfigurationType) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            let bindIdentifier = configuration.bindIdentifier
            if let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
               identifierPattern.identifier.text != bindIdentifier {
                var hasViolation = false
                if let initializerIdentifier = node.initializer?.value.as(DeclReferenceExprSyntax.self) {
                    hasViolation = initializerIdentifier.baseName.text == "self"
                } else if node.initializer == nil {
                    hasViolation = identifierPattern.identifier.text == "self" && bindIdentifier != "self"
                }

                if hasViolation {
                    violations.append(
                        ReasonedRuleViolation(
                            position: identifierPattern.positionAfterSkippingLeadingTrivia,
                            reason: "`self` should always be re-bound to `\(bindIdentifier)`"
                        )
                    )
                }
            }
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        private let bindIdentifier: String
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(bindIdentifier: String, locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.bindIdentifier = bindIdentifier
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
            guard
                let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
                identifierPattern.identifier.text != bindIdentifier,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            if let initializerIdentifier = node.initializer?.value.as(DeclReferenceExprSyntax.self),
               initializerIdentifier.baseName.text == "self" {
                correctionPositions.append(identifierPattern.positionAfterSkippingLeadingTrivia)

                let newPattern = PatternSyntax(
                    identifierPattern
                        .with(\.identifier, identifierPattern.identifier.with(\.tokenKind, .identifier(bindIdentifier)))
                )

                return super.visit(node.with(\.pattern, newPattern))
            } else if node.initializer == nil, identifierPattern.identifier.text == "self", bindIdentifier != "self" {
                correctionPositions.append(identifierPattern.positionAfterSkippingLeadingTrivia)

                let newPattern = PatternSyntax(
                    identifierPattern
                        .with(\.identifier, identifierPattern.identifier.with(\.tokenKind, .identifier(bindIdentifier)))
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
            } else {
                return super.visit(node)
            }
        }
    }
}
