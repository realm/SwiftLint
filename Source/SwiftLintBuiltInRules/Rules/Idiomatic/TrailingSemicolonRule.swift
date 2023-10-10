import SwiftSyntax

@SwiftSyntaxRule
struct TrailingSemicolonRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "trailing_semicolon",
        name: "Trailing Semicolon",
        description: "Lines should not have trailing semicolons",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let a = 0"),
            Example("let a = 0; let b = 0")
        ],
        triggeringExamples: [
            Example("let a = 0↓;\n"),
            Example("let a = 0↓;\nlet b = 1"),
            Example("let a = 0↓; // a comment\n")
        ],
        corrections: [
            Example("let a = 0↓;\n"): Example("let a = 0\n"),
            Example("let a = 0↓;\nlet b = 1"): Example("let a = 0\nlet b = 1"),
            Example("let foo = 12↓;  // comment\n"): Example("let foo = 12  // comment\n")
        ]
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension TrailingSemicolonRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: TokenSyntax) {
            if node.isTrailingSemicolon {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: TokenSyntax) -> TokenSyntax {
            guard
                node.isTrailingSemicolon,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            return .unknown("").with(\.trailingTrivia, node.trailingTrivia)
        }
    }
}

private extension TokenSyntax {
    var isTrailingSemicolon: Bool {
        tokenKind == .semicolon &&
            (
                trailingTrivia.containsNewlines() ||
                    (nextToken(viewMode: .sourceAccurate)?.leadingTrivia.containsNewlines() == true)
            )
    }
}
