import Foundation
import SwiftSyntax

struct InvalidSwiftLintCommandRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "invalid_swiftlint_command",
        name: "Invalid SwiftLint Command",
        description: "swiftlint command does not have a valid action or modifier",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// swiftlint:disable unused_import"),
            Example("// swiftlint:enable unused_import"),
            Example("// swiftlint:disable:next unused_import"),
            Example("// swiftlint:disable:previous unused_import"),
            Example("// swiftlint:disable:this unused_import")
        ],
        triggeringExamples: [
            Example("// ↓swiftlint:"),
            Example("// ↓swiftlint: "),
            Example("// ↓swiftlint::"),
            Example("// ↓swiftlint:: "),
            Example("// ↓swiftlint:disable"),
            Example("// ↓swiftlint:dissable unused_import"),
            Example("// ↓swiftlint:enaaaable unused_import"),
            Example("// ↓swiftlint:disable:nxt unused_import"),
            Example("// ↓swiftlint:enable:prevus unused_import"),
            Example("// ↓swiftlint:enable:ths unused_import"),
            Example("// ↓swiftlint:enable"),
            Example("// ↓swiftlint:enable:"),
            Example("// ↓swiftlint:enable: "),
            Example("// ↓swiftlint:disable: unused_import")
        ].skipWrappingInCommentTests()
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension InvalidSwiftLintCommandRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: TokenSyntax) {
            let leadingViolations = node.leadingTrivia.violations(offset: node.position)
            violations.append(contentsOf: leadingViolations)
            let trailingViolations = node.trailingTrivia.violations(offset: node.endPositionBeforeTrailingTrivia)
            violations.append(contentsOf: trailingViolations)
        }
    }
}

// MARK: - Private Helpers
private extension Trivia {
    func violations(offset: AbsolutePosition) -> [ReasonedRuleViolation] {
        var triviaOffset = SourceLength.zero
        var violations: [ReasonedRuleViolation] = []
        for trivia in self {
            switch trivia {
            case .lineComment(let comment), .blockComment(let comment):
                if let lower = comment.range(of: "swiftlint:")?.lowerBound,
                   case let actionString = String(comment[lower...]) {
                    let swiftLintOffset = comment.distance(from: comment.startIndex, to: lower)
                    let violationOffset = (offset + triviaOffset).advanced(by: swiftLintOffset)
                    if let violation = violation(forString: actionString, offset: violationOffset) {
                        violations.append(violation)
                    }
                }
            default:
                break
            }
            triviaOffset += trivia.sourceLength
        }

        return violations
    }

    private func violation(forString actionString: String, offset: AbsolutePosition) -> ReasonedRuleViolation? {
        guard Command(actionString: actionString, line: 0, character: 0) != nil else {
            ReasonedRuleViolation(position: offset)
        }
        return nil
    }
}
