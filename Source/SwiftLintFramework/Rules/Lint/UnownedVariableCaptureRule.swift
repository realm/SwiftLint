import SwiftSyntax

public struct UnownedVariableCaptureRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unowned_variable_capture",
        name: "Unowned Variable Capture",
        description: "Prefer capturing references as weak to avoid potential crashes.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("foo { [weak self] in _ }"),
            Example("foo { [weak self] param in _ }"),
            Example("foo { [weak bar] in _ }"),
            Example("foo { [weak bar] param in _ }"),
            Example("foo { bar in _ }"),
            Example("foo { $0 }")
        ],
        triggeringExamples: [
            Example("foo { [↓unowned self] in _ }"),
            Example("foo { [↓unowned bar] in _ }"),
            Example("foo { [bar, ↓unowned self] in _ }")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        UnownedVariableCaptureRuleVisitor(viewMode: .sourceAccurate)
    }
}

private final class UnownedVariableCaptureRuleVisitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []

    override func visitPost(_ node: ClosureCaptureItemSyntax) {
        if let token = node.unownedToken {
            violationPositions.append(token.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: TokenListSyntax) {
        if case .contextualKeyword("unowned") = node.first?.tokenKind {
            violationPositions.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension ClosureCaptureItemSyntax {
    var unownedToken: TokenSyntax? {
        specifier?.first { token in
            token.tokenKind == .identifier("unowned")
        }
    }
}
