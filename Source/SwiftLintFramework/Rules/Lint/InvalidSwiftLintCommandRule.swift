//
//  InvalidSwiftLintDirectiveRule.swift
//  
//
//  Created by martin.redington on 12/11/2022.
//

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
            Example("// swiftlint:disable some_rule"),
            Example("// swiftlint:enable some_rule"),
            Example("// swiftlint:disable:next some_rule"),
            Example("// swiftlint:disable:previous some_rule")
        ],
        triggeringExamples: [
            Example("// swiftlint:"),
            Example("// swiftlint::"),
            Example("// swiftlint:disable"),
            Example("// swiftlint:dissable unused_import"),
            Example("// swiftlint:enaaaable unused_import"),
            Example("// swiftlint:disable:nxt unused_import"),
            Example("// swiftlint:enable:prevus unused_import"),
            Example("// swiftlint:enable"),
            Example("// swiftlint:disable: unused_import")
        ]
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

    private func violation(forString actionString: String, offset: AbsolutePosition) -> ReasonedRuleViolation? {
        guard let command = Command(actionString: actionString, line: 0, character: 0) else {
            let violation = ReasonedRuleViolation(position: offset)
            return violation
        }
        if command.modifier == nil {
            return malformedModifierViolation(forString: actionString, offset: offset)
        }
        return nil
    }

    private func malformedModifierViolation(
        forString actionString: String,
        offset: AbsolutePosition
    ) -> ReasonedRuleViolation? {
        if let malformedEnableViolation = malformedModifierViolation(
            commandAndAction: "swiftlint:enable:",
            forString: actionString,
            offset: offset
        ) {
            return malformedEnableViolation
        }
        return malformedModifierViolation(
            commandAndAction: "swiftlint:disable:",
            forString: actionString,
            offset: offset
        )
    }

    private func malformedModifierViolation(
        commandAndAction: String,
        forString actionString: String,
        offset: AbsolutePosition
    ) -> ReasonedRuleViolation? {
        let scanner = Scanner(string: actionString)
        guard scanner.scanString(commandAndAction) != nil else {
            return nil
        }
        guard let modifierString = scanner.scanUpToString(" ") else {
            return nil
        }
        if Command.Modifier(rawValue: modifierString) == nil {
            return ReasonedRuleViolation(position: offset)
        }
        return nil
    }
}
