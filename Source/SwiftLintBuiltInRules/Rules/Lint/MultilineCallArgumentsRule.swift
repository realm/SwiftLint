import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MultilineCallArgumentsRule: Rule {
    var configuration = MultilineCallArgumentsConfiguration()

    enum Reason {
        static let singleLineMultipleArgumentsNotAllowed =
            "Single-line calls with multiple arguments are not allowed"

        static func tooManyArgumentsOnSingleLine(max: Int) -> String {
            "Too many arguments on a single line (max: \(max))"
        }

        static let eachArgumentMustStartOnOwnLine =
            "In multi-line calls, each argument must start on its own line"
    }

    static let description = RuleDescription(
        identifier: "multiline_call_arguments",
        name: "Multiline Call Arguments",
        description: """
                     Enforces one-argument-per-line for multi-line calls; \
                     optionally limits or forbids multi-argument single-line calls via configuration
                     """,
        kind: .style,
        nonTriggeringExamples: MultilineCallArgumentsRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineCallArgumentsRuleExamples.triggeringExamples
    )
}

private extension MultilineCallArgumentsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        /// Cache line lookups by utf8Offset (stable, cheap key)
        private var lineCache: [Int: Int] = [:]

        override init(configuration: ConfigurationType, file: SwiftLintFile) {
            super.init(configuration: configuration, file: file)

            // Most files trigger O(10–100) unique line lookups for this rule.
            // Reserving a small initial capacity reduces rehashing; it is NOT a hard limit.
            lineCache.reserveCapacity(64)
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            // Ignore calls that are part of pattern-matching syntax (patterns only, not bodies).
            guard !node.isInPatternMatchingPatternPosition else { return }

            let args = node.arguments
            guard args.count > 1 else { return }

            let argumentPositions = args.map(\.positionAfterSkippingLeadingTrivia)
            guard let violation = reasonedViolation(argumentPositions: argumentPositions) else { return }
            violations.append(violation)
        }

        private func reasonedViolation(argumentPositions: [AbsolutePosition]) -> ReasonedRuleViolation? {
            guard let firstPos = argumentPositions.first else { return nil }

            let firstLine = line(for: firstPos)
            var allOnSameLine = true

            for pos in argumentPositions.dropFirst() where line(for: pos) != firstLine {
                allOnSameLine = false
                break
            }

            if allOnSameLine {
                if !configuration.allowsSingleLine {
                    return ReasonedRuleViolation(
                        position: argumentPositions[1],
                        reason: Reason.singleLineMultipleArgumentsNotAllowed
                    )
                }

                if let max = configuration.maxNumberOfSingleLineParameters,
                   argumentPositions.count > max {
                    return ReasonedRuleViolation(
                        position: argumentPositions[max],
                        reason: Reason.tooManyArgumentsOnSingleLine(max: max)
                    )
                }

                return nil
            }

            var seen: Set<Int> = []
            for pos in argumentPositions {
                let line = line(for: pos)
                if !seen.insert(line).inserted {
                    return ReasonedRuleViolation(
                        position: pos,
                        reason: Reason.eachArgumentMustStartOnOwnLine
                    )
                }
            }

            return nil
        }

        private func line(for position: AbsolutePosition) -> Int {
            let key = position.utf8Offset
            if let cached = lineCache[key] { return cached }
            let line = locationConverter.location(for: position).line
            lineCache[key] = line
            return line
        }
    }
}

// MARK: - Pattern filtering (precise, pattern-part only)

private extension FunctionCallExprSyntax {
    /// `true` only when this FunctionCall is used inside a *pattern* (e.g. `.caseOne(...)`),
    /// not just somewhere inside `if case` / `switch case` bodies.
    var isInPatternMatchingPatternPosition: Bool {
        let selfSyntax = Syntax(self)
        var current: Syntax? = parent

        // Low-level pattern nodes can appear inside multiple contexts; we only need to check each once.
        var checkedExpressionPattern = false
        var checkedValueBindingPattern = false

        while let node = current {
            if !checkedExpressionPattern, let expressionPattern = node.as(ExpressionPatternSyntax.self) {
                checkedExpressionPattern = true
                if selfSyntax.isInside(Syntax(expressionPattern.expression)) { return true }
            }

            if !checkedValueBindingPattern, let valueBindingPattern = node.as(ValueBindingPatternSyntax.self) {
                checkedValueBindingPattern = true
                if selfSyntax.isInside(Syntax(valueBindingPattern.pattern)) { return true }
            }

            // Once we reach a *top-level* pattern container (if/switch/for/catch),
            // we can safely stop walking up the parent chain after checking its pattern subtree.

            if let condition = node.as(MatchingPatternConditionSyntax.self) {
                if selfSyntax.isInside(Syntax(condition.pattern)) { return true }
                break
            }

            if let caseItem = node.as(SwitchCaseItemSyntax.self) {
                if selfSyntax.isInside(Syntax(caseItem.pattern)) { return true }
                break
            }

            if let forStmt = node.as(ForStmtSyntax.self) {
                if selfSyntax.isInside(Syntax(forStmt.pattern)) { return true }
                break
            }

            if let catchClause = node.as(CatchClauseSyntax.self) {
                for item in catchClause.catchItems {
                    if let pattern = item.pattern,
                       selfSyntax.isInside(Syntax(pattern)) {
                        return true
                    }
                }
                break
            }

            current = node.parent
        }

        return false
    }
}

// MARK: - Generic helpers

private extension Syntax {
    /// Returns `true` if `self` is the `ancestor` node itself or is located inside its subtree.
    func isInside(_ ancestor: Syntax) -> Bool {
        var current: Syntax? = self
        while let node = current {
            if node.id == ancestor.id { return true }
            current = node.parent
        }
        return false
    }
}
