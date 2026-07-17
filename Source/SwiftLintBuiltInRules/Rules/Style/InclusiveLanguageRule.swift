import Foundation
import SwiftSyntax

@SwiftSyntaxRule
struct InclusiveLanguageRule: Rule {
    var configuration = InclusiveLanguageConfiguration()

    static let description = RuleDescription(
        identifier: "inclusive_language",
        name: "Inclusive Language",
        description: """
            Identifiers should use inclusive language that avoids discrimination against groups of people based on \
            race, gender, or socioeconomic status.
            """,
        kind: .style,
        nonTriggeringExamples: InclusiveLanguageRuleExamples.nonTriggeringExamples,
        triggeringExamples: InclusiveLanguageRuleExamples.triggeringExamples
    )
}

private extension InclusiveLanguageRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private lazy var allTerms = configuration.allTerms
        private lazy var allAllowedTerms = configuration.allAllowedTerms
        /// The UTF-8 bytes of every all-ASCII term, or `nil` for terms containing non-ASCII characters, which must
        /// always take the full Unicode-aware search path.
        private lazy var allTermsUTF8: [[UInt8]?] = configuration.allTerms.map { term in
            let utf8 = Array(term.utf8)
            return utf8.allSatisfy({ $0 < 0x80 }) ? utf8 : nil
        }

        override func visitPost(_ node: IdentifierPatternSyntax) {
            if let violation = violation(for: node.identifier) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: GenericParameterSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: FunctionParameterSyntax) {
            if let violation = violation(for: node.firstName) {
                violations.append(violation)
            }

            if let name = node.secondName, let violation = violation(for: name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: AccessorParametersSyntax) {
            if let violation = violation(for: node.name) {
                violations.append(violation)
            }
        }

        override func visit(_: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        private func violation(for node: TokenSyntax) -> ReasonedRuleViolation? {
            guard let (term, name) = violationTerm(for: node) else {
                return nil
            }

            return ReasonedRuleViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: "Declaration \(name) contains the term \"\(term)\" which is not considered inclusive"
            )
        }

        private func violationTerm(for node: TokenSyntax) -> (violationTerm: String, name: String)? {
            let name = node.text
            let lowercased = name.lowercased()
            guard mayContainViolationTerm(in: lowercased) else {
                return nil
            }
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

        /// A cheap byte-level pre-check ruling out names that cannot contain any term. For all-ASCII names — the
        /// overwhelmingly common case — an all-ASCII term can only be found if its UTF-8 bytes occur verbatim in the
        /// lowercased name, so most names are filtered out here without paying for the expensive Unicode-aware
        /// searches in `violationTerm(for:)`. Non-ASCII names and terms always pass so that the full search decides.
        private func mayContainViolationTerm(in lowercasedName: String) -> Bool {
            var lowercasedName = lowercasedName
            return lowercasedName.withUTF8 { name in
                guard name.allSatisfy({ $0 < 0x80 }) else {
                    return true
                }
                return allTermsUTF8.contains { term in
                    guard let term else {
                        // A non-ASCII term may match ASCII names in exotic ways; let the full search decide.
                        return true
                    }
                    return contains(term, in: name)
                }
            }
        }

        private func contains(_ term: [UInt8], in name: UnsafeBufferPointer<UInt8>) -> Bool {
            if term.isEmpty {
                // Be conservative and let `violationTerm(for:)` decide.
                return true
            }
            guard term.count <= name.count else {
                return false
            }
            for start in 0...(name.count - term.count) {
                var offset = 0
                while offset < term.count, name[start + offset] == term[offset] {
                    offset += 1
                }
                if offset == term.count {
                    return true
                }
            }
            return false
        }
    }
}
