import SwiftSyntax

// MARK: - SelfBindingRule

public struct SelfBindingRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SelfBindingConfiguration()

    public init() {}

    public static let description = RuleDescription(
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
            Example("guard let ↓self = self else else { return }", configuration: ["bind_identifier": "this"])
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
                Example("if let this = self { return }", configuration: ["bind_identifier": "this"])
        ]
    )

    public func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severityConfiguration.severity,
            location: Location(file: file, position: position),
            reason: "`self` should always be re-bound to `\(configuration.bindIdentifier)`"
        )
    }

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        SelfBindingRuleVisitor(bindIdentifier: configuration.bindIdentifier)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
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
           identifierPattern.identifier.text != bindIdentifier,
           let initializerIdentifier = node.initializer?.value.as(IdentifierExprSyntax.self),
           initializerIdentifier.identifier.text == "self" {
            violationPositions.append(identifierPattern.positionAfterSkippingLeadingTrivia)
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

    override func visit(_ node: OptionalBindingConditionSyntax) -> Syntax {
        guard
            let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
            identifierPattern.identifier.text != bindIdentifier,
            let initializerIdentifier = node.initializer?.value.as(IdentifierExprSyntax.self),
            initializerIdentifier.identifier.text == "self",
            !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
        else {
            return super.visit(node)
        }

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
    }
}
