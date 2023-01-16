import SwiftSyntax

// MARK: - SelfBindingRule

struct SelfBindingRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SelfBindingConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "self_binding",
        name: "Self Binding",
        description: "Re-bind `self` to a consistent identifier name.",
        kind: .style,
        nonTriggeringExamples: [
            Example("if let self = self { return }"),
            Example("guard let self = self else else { return }"),
            Example("if let this = this { return }"),
            Example("guard let this = this else else { return }"),
            Example("if let this = self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let this = self else else { return }", configuration: ["bind_identifier": "this"])
        ],
        triggeringExamples: [
            Example("if let ↓`self` = self { return }"),
            Example("guard let ↓`self` = self else else { return }"),
            Example("if let ↓this = self { return }"),
            Example("guard let ↓this = self else else { return }"),
            Example("if let ↓self = self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let ↓self = self else { return }", configuration: ["bind_identifier": "this"]),
            Example("if let ↓self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let ↓self else { return }", configuration: ["bind_identifier": "this"])
        ],
        corrections: [
            Example("if let ↓`self` = self { return }"):
                Example("if let self = self { return }"),
            Example("guard let ↓`self` = self else else { return }"):
                Example("guard let self = self else else { return }"),
            Example("if let ↓this = self { return }"):
                Example("if let self = self { return }"),
            Example("guard let ↓this = self else else { return }"):
                Example("guard let self = self else else { return }"),
            Example("if let ↓self = self { return }", configuration: ["bind_identifier": "this"]):
                Example("if let this = self { return }", configuration: ["bind_identifier": "this"]),
            Example("if let ↓self { return }", configuration: ["bind_identifier": "this"]):
                Example("if let this = self { return }", configuration: ["bind_identifier": "this"]),
            Example("guard let ↓self else { return }", configuration: ["bind_identifier": "this"]):
                Example("guard let this = self else { return }", configuration: ["bind_identifier": "this"])
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        SelfBindingRuleVisitor(bindIdentifier: configuration.bindIdentifier)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        SelfBindingRuleRewriter(
            bindIdentifier: configuration.bindIdentifier,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

// MARK: - SelfBindingRuleVisitor

private final class SelfBindingRuleVisitor: ViolationsSyntaxVisitor {
    private let bindIdentifier: String

    init(bindIdentifier: String) {
        self.bindIdentifier = bindIdentifier
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: OptionalBindingConditionSyntax) {
        if let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
           identifierPattern.identifier.text != bindIdentifier {
            var hasViolation = false
            if let initializerIdentifier = node.initializer?.value.as(IdentifierExprSyntax.self) {
                hasViolation = initializerIdentifier.identifier.text == "self"
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

// MARK: - SelfBindingRuleRewriter

private final class SelfBindingRuleRewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
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

        if let initializerIdentifier = node.initializer?.value.as(IdentifierExprSyntax.self),
           initializerIdentifier.identifier.text == "self" {
            correctionPositions.append(identifierPattern.positionAfterSkippingLeadingTrivia)

            return super.visit(
                node.withPattern(
                    PatternSyntax(
                        identifierPattern.withIdentifier(
                            identifierPattern.identifier.withKind(.identifier(bindIdentifier))
                        )
                    )
                )
            )
        } else if node.initializer == nil, identifierPattern.identifier.text == "self", bindIdentifier != "self" {
            correctionPositions.append(identifierPattern.positionAfterSkippingLeadingTrivia)

            let newNode = node
                .withPattern(
                    PatternSyntax(
                        identifierPattern.withIdentifier(
                            identifierPattern.identifier.withKind(.identifier(bindIdentifier))
                        )
                    )
                )
                .withInitializer(
                    InitializerClauseSyntax(
                        value: IdentifierExprSyntax(
                            identifier: .selfKeyword(
                                leadingTrivia: .space,
                                trailingTrivia: identifierPattern.trailingTrivia ?? .space
                            )
                        )
                    )
                )
            return super.visit(newNode)
        } else {
            return super.visit(node)
        }
    }
}
