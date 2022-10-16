import SwiftSyntax

public struct InclusiveLanguageRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = InclusiveLanguageConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "inclusive_language",
        name: "Inclusive Language",
        description: """
            Identifiers should use inclusive language that avoids discrimination against groups of people based on \
            race, gender, or socioeconomic status
            """,
        kind: .style,
        nonTriggeringExamples: InclusiveLanguageRuleExamples.nonTriggeringExamples,
        triggeringExamples: InclusiveLanguageRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(allTerms: configuration.allTerms, allAllowedTerms: configuration.allAllowedTerms)
    }
}

private extension InclusiveLanguageRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let allTerms: Set<String>
        private let allAllowedTerms: Set<String>

        init(allTerms: Set<String>, allAllowedTerms: Set<String>) {
            self.allTerms = allTerms
            self.allAllowedTerms = allAllowedTerms
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: TokenSyntax) {
            let name = node.withoutTrivia().text
            let lowercased = name.lowercased()
            let sortedTerms = allTerms.sorted()
            let violationTerm = sortedTerms.first { term in
                guard let range = lowercased.range(of: term) else { return false }
                let overlapsAllowedTerm = allAllowedTerms.contains { allowedTerm in
                    guard let allowedRange = lowercased.range(of: allowedTerm) else { return false }
                    return range.overlaps(allowedRange)
                }
                return !overlapsAllowedTerm
            }

            guard let term = violationTerm else {
                return
            }

            violations.append(ReasonedRuleViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: "Declaration \(name) contains the term \"\(term)\" which is not considered inclusive."
            ))
        }

        override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}
