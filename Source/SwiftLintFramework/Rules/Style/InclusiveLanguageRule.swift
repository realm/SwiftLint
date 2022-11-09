import SwiftSyntax

struct InclusiveLanguageRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = InclusiveLanguageConfiguration()

    init() {}

    static let description = RuleDescription(
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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(allTerms: configuration.allTerms, allAllowedTerms: configuration.allAllowedTerms)
    }
}

private extension InclusiveLanguageRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let allTerms: [String]
        private let allAllowedTerms: Set<String>

        init(allTerms: [String], allAllowedTerms: Set<String>) {
            self.allTerms = allTerms
            self.allAllowedTerms = allAllowedTerms
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: IdentifierPatternSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: TypealiasDeclSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: GenericParameterSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: AssociatedtypeDeclSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: FunctionParameterSyntax) {
            if let name = node.firstName, let violation = violation(for: name) {
                violations.append(violation)
            }

            if let name = node.secondName, let violation = violation(for: name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: AccessorParameterSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        private func violation(for node: TokenSyntax) -> ReasonedRuleViolation? {
            guard let (term, name) = violationTerm(for: node) else {
                return nil
            }

            return ReasonedRuleViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: "Declaration \(name) contains the term \"\(term)\" which is not considered inclusive."
            )
        }

        private func violationTerm(for node: TokenSyntax) -> (violationTerm: String, name: String)? {
            let name = node.text
            let lowercased = name.lowercased()
            let violationTerm = allTerms.first { term in
                guard let range = lowercased.range(of: term) else { return false }
                let overlapsAllowedTerm = allAllowedTerms.contains { allowedTerm in
                    guard let allowedRange = lowercased.range(of: allowedTerm) else { return false }
                    return range.overlaps(allowedRange)
                }
                return !overlapsAllowedTerm
            }

            return violationTerm.map { (violationTerm: $0, name: name) }
        }
    }
}
