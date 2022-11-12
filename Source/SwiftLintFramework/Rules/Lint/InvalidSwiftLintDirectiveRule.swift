//
//  InvalidSwiftLintDirectiveRule.swift
//  
//
//  Created by martin.redington on 12/11/2022.
//

import SwiftSyntax

struct InvalidSwiftLintDirectiveRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "invalid_swiftlint_directive",
        name: "Invalid SwiftLint Directive",
        description: "swiftlint directive does not have a valid action or modifier",
        kind: .performance,
        nonTriggeringExamples: [
            Example("// swiftlint:disable some_rule"),
            Example("// swiftlint:enable some_rule"),
            Example("// swiftlint:disable:next some_rule"),
            Example("// swiftlint:disable:previous some_rule")
        ],
        triggeringExamples: [
            Example("// swiftlint:dissable some_rule"),
            Example("// swiftlint:enabel some_rule"),
            Example("// swiftlint:disable:nxt some_rule"),
            Example("// swiftlint:disable:prevous some_rule")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension InvalidSwiftLintDirectiveRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: TokenSyntax) {
//            guard
//                node.tokenKind.isEqualityComparison,
//                let violationPosition = node.previousToken?.endPositionBeforeTrailingTrivia,
//                let expectedLeftSquareBracketToken = node.nextToken,
//                expectedLeftSquareBracketToken.tokenKind == .leftSquareBracket,
//                let expectedColonToken = expectedLeftSquareBracketToken.nextToken,
//                expectedColonToken.tokenKind == .colon || expectedColonToken.tokenKind == .rightSquareBracket
//            else {
//                return
//            }

            let leadingViolations = node.leadingTrivia.violations(offset: node.position)
            let trailingViolations = node.trailingTrivia.violations(offset: node.endPositionBeforeTrailingTrivia)

            violations.append(contentsOf: leadingViolations)
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
            triviaOffset += trivia.sourceLength
            switch trivia {
            case .lineComment(let comment), .blockComment(let comment):
                if
                    let lower = comment.range(of: "swiftlint:")?.lowerBound,
                    case let actionString = String(comment[lower...]),
                    let violation = violation(forString: actionString, offset: offset + triviaOffset) {
                    violations.append(violation)
                }
            default:
                break
            }
        }

        return violations
    }

    func violation(forString actionString: String, offset: AbsolutePosition) -> ReasonedRuleViolation? {
        if Command(actionString: actionString, line: 0, character: 0) == nil {
            let violation = ReasonedRuleViolation(position: offset)
            return violation
        }
        return nil
    }
}
