import SwiftSyntax

public struct ClosingBraceRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closing_brace",
        name: "Closing Brace Spacing",
        description: "Closing brace with closing parenthesis should not have any whitespaces in the middle.",
        kind: .style,
        nonTriggeringExamples: [
            Example("[].map({ })"),
            Example("[].map(\n  { }\n)")
        ],
        triggeringExamples: [
            Example("[].map({ ↓} )"),
            Example("[].map({ ↓}\t)")
        ],
        corrections: [
            Example("[].map({ ↓} )\n"): Example("[].map({ })\n")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        file.locationConverter.map { locationConverter in
            Rewriter(
                locationConverter: locationConverter,
                disabledRegions: disabledRegions(file: file)
            )
        }
    }
}

private extension ClosingBraceRule {
    private final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: TokenSyntax) {
            if node.hasClosingBraceViolation {
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    private final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: TokenSyntax) -> Syntax {
            guard node.hasClosingBraceViolation else {
                return super.visit(node)
            }

            let isInDisabledRegion = disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }

            guard !isInDisabledRegion else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            return super.visit(node.withTrailingTrivia(.zero))
        }
    }
}

private extension TokenSyntax {
    var hasClosingBraceViolation: Bool {
        guard tokenKind == .rightBrace,
           let nextToken = nextToken,
           nextToken.tokenKind == .rightParen
        else {
            return false
        }

        let isImmediatelyNext = positionAfterSkippingLeadingTrivia
            == nextToken.positionAfterSkippingLeadingTrivia - SourceLength(utf8Length: 1)
        if isImmediatelyNext || nextToken.hasLeadingNewline {
            return false
        } else {
            return true
        }
    }

    private var hasLeadingNewline: Bool {
        leadingTrivia.contains { piece in
            if case .newlines = piece {
                return true
            } else {
                return false
            }
        }
    }
}
