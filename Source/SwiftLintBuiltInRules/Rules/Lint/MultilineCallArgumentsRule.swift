// swiftlint:disable file_length

import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
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

        static let newlineRequiredAfterCommaInMultilineCall =
            "In multi-line calls, a newline is required after each comma"
    }

    static let description = RuleDescription(
        identifier: "multiline_call_arguments",
        name: "Multiline Call Arguments",
        description: """
        Enforces one-argument-per-line for multi-line calls and requires a newline after commas \
        when arguments are split across lines;
        optionally limits or forbids multi-argument single-line calls via configuration.
        """,
        rationale: """
        Keeping each argument on its own line in multi-line calls improves readability and
        reduces merge conflicts. Requiring a newline after commas makes the call's structure
        immediately visible and avoids ambiguous layouts where arguments appear to share a line.
        """,
        kind: .style,
        nonTriggeringExamples: MultilineCallArgumentsRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineCallArgumentsRuleExamples.triggeringExamples,
        corrections: MultilineCallArgumentsRuleExamples.corrections
    )
}

private extension MultilineCallArgumentsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        /// Cache line lookups by utf8Offset (stable, cheap key)
        private var lineCache: [Int: Int] = [:]

        private static let closingTokensThatSkipNewlineAfterComma: [TokenKind] = [.rightBrace, .rightSquare]

        override init(configuration: ConfigurationType, file: SwiftLintFile) {
            super.init(configuration: configuration, file: file)

            // Most files trigger O(10–100) unique line lookups for this rule.
            // Reserving a small initial capacity reduces rehashing; it is NOT a hard limit.
            lineCache.reserveCapacity(64)
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            // Ignore calls that are part of pattern-matching syntax (patterns only, not bodies).
            guard !node.isInPatternMatchingPatternPosition else { return }

            let arguments = Array(node.arguments)
            guard arguments.count > 1 else { return }

            let argumentPositions = arguments.map(\.positionAfterSkippingLeadingTrivia)
            violations.append(
                contentsOf: violations(
                    argumentPositions: argumentPositions,
                    arguments: arguments,
                    callNode: node
                )
            )
        }

        private func violations(
            argumentPositions: [AbsolutePosition],
            arguments: [LabeledExprSyntax],
            callNode: FunctionCallExprSyntax
        ) -> [ReasonedRuleViolation] {
            guard let firstPosition = argumentPositions.first else { return [] }

            let firstLine = line(for: firstPosition)
            let allOnSameLine = argumentPositions.allSatisfy { line(for: $0) == firstLine }

            if allOnSameLine {
                if !configuration.allowsSingleLine {
                    return [
                        ReasonedRuleViolation(
                            position: argumentPositions[1],
                            reason: Reason.singleLineMultipleArgumentsNotAllowed,
                            correction: correctSingleLine(arguments: arguments, callNode: callNode)
                        ),
                    ]
                }

                if let max = configuration.maxNumberOfSingleLineParameters,
                   argumentPositions.count > max {
                    return [
                        ReasonedRuleViolation(
                            position: argumentPositions[max],
                            reason: Reason.tooManyArgumentsOnSingleLine(max: max),
                            correction: correctSingleLine(arguments: arguments, callNode: callNode)
                        ),
                    ]
                }

                return []
            }

            let hasArgsComments = arguments.contains(where: \.hasComments)
            let baseIndent = baseIndent(for: callNode)

            guard let violation = fullExpansionViolation(
                arguments: arguments,
                callNode: callNode,
                hasComments: hasArgsComments,
                baseIndent: baseIndent
            ) else {
                return multilineViolations(
                    arguments: arguments,
                    callNode: callNode,
                    hasComments: hasArgsComments,
                    baseIndent: baseIndent
                )
            }
            return [violation]
        }

        private func fullExpansionViolation(
            arguments: [LabeledExprSyntax],
            callNode: FunctionCallExprSyntax,
            hasComments: Bool,
            baseIndent: String
        ) -> ReasonedRuleViolation? {
            guard
                arguments.count == 2,
                let rightParen = callNode.rightParen,
                !hasComments,
                let comma = arguments[0].trailingComma, comma.presence != .missing,
                !endsWithClosingToken(argument: arguments[0])
            else { return nil }

            let first = arguments[0]
            let second = arguments[1]
            let callStartLine = line(for: callNode.positionAfterSkippingLeadingTrivia)
            let firstStartLine = line(for: startPosition(of: first))
            let secondStart = startPosition(of: second)
            let secondStartLine = line(for: secondStart)
            let commaLine = line(for: comma.positionAfterSkippingLeadingTrivia)

            guard firstStartLine == callStartLine,
                  commaLine == secondStartLine,
                  firstStartLine != secondStartLine,
                  line(for: rightParen.positionAfterSkippingLeadingTrivia) == secondStartLine else { return nil }

            return ReasonedRuleViolation(
                position: secondStart,
                reason: Reason.newlineRequiredAfterCommaInMultilineCall,
                correction: correctFullyExpanded(
                    firstArgument: first,
                    lastArgument: second,
                    rightParen: rightParen,
                    baseIndent: baseIndent
                )
            )
        }

        private func multilineViolations(
            arguments: [LabeledExprSyntax],
            callNode: FunctionCallExprSyntax,
            hasComments: Bool,
            baseIndent: String
        ) -> [ReasonedRuleViolation] {
            var result: [ReasonedRuleViolation] = []
            for index in arguments.indices.dropLast() {
                let currentArgument = arguments[index]
                let next = arguments[index + 1]

                guard let comma = currentArgument.trailingComma, comma.presence != .missing else { continue }

                let currentStartLine = line(for: startPosition(of: currentArgument))
                let nextStart = startPosition(of: next)
                let nextStartLine = line(for: nextStart)

                if currentStartLine == nextStartLine {
                    let correction: ReasonedRuleViolation.ViolationCorrection? = if hasComments {
                        nil
                    } else {
                        correctNewlineAndIndent(
                            start: currentArgument.endPositionBeforeTrailingTrivia,
                            end: nextStart,
                            baseIndent: baseIndent
                        )
                    }
                    result.append(
                        ReasonedRuleViolation(
                            position: nextStart,
                            reason: Reason.eachArgumentMustStartOnOwnLine,
                            correction: correction
                        )
                    )
                } else if !endsWithClosingToken(argument: currentArgument) {
                    let commaLine = line(for: comma.positionAfterSkippingLeadingTrivia)
                    guard commaLine == nextStartLine else { continue }

                    let correction: ReasonedRuleViolation.ViolationCorrection? = if hasComments {
                        nil
                    } else if let rightParen = callNode.rightParen,
                              index == arguments.count - 2,
                              line(for: rightParen.positionAfterSkippingLeadingTrivia) == nextStartLine {
                        correctCloseParen(
                            comma: comma,
                            lastArgument: next,
                            rightParen: rightParen,
                            baseIndent: baseIndent
                        )
                    } else {
                        correctNewlineAndIndent(
                            start: comma.endPositionBeforeTrailingTrivia,
                            end: nextStart,
                            baseIndent: baseIndent
                        )
                    }

                    result.append(
                        ReasonedRuleViolation(
                            position: nextStart,
                            reason: Reason.newlineRequiredAfterCommaInMultilineCall,
                            correction: correction
                        )
                    )
                }
            }
            return result
        }

        private func correctNewlineAndIndent(
            start: AbsolutePosition,
            end: AbsolutePosition,
            baseIndent: String
        ) -> ReasonedRuleViolation.ViolationCorrection {
            ReasonedRuleViolation.ViolationCorrection(
                start: start,
                end: end,
                replacement: "\n" + (baseIndent + oneLevel)
            )
        }

        private func normalizedText(argument: LabeledExprSyntax) -> String {
            argument.description.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
        }

        private func correctCloseParen(
            comma: TokenSyntax,
            lastArgument: LabeledExprSyntax,
            rightParen: TokenSyntax,
            baseIndent: String
        ) -> ReasonedRuleViolation.ViolationCorrection {
            ReasonedRuleViolation.ViolationCorrection(
                start: comma.endPositionBeforeTrailingTrivia,
                end: rightParen.positionAfterSkippingLeadingTrivia,
                replacement: "\n" + baseIndent + oneLevel + normalizedText(argument: lastArgument) + "\n" + baseIndent
            )
        }

        private func correctFullyExpanded(
            firstArgument: LabeledExprSyntax,
            lastArgument: LabeledExprSyntax,
            rightParen: TokenSyntax,
            baseIndent: String
        ) -> ReasonedRuleViolation.ViolationCorrection {
            let indentUnit = oneLevel
            let indent = baseIndent + indentUnit
            let reindented = normalizedText(argument: firstArgument)
                .split(separator: "\n", omittingEmptySubsequences: false)
                .enumerated()
                .map { $0.offset == 0 ? String($0.element) : indentUnit + $0.element }
                .joined(separator: "\n")

            return ReasonedRuleViolation.ViolationCorrection(
                start: firstArgument.position,
                end: rightParen.endPositionBeforeTrailingTrivia,
                replacement: "\n" + indent + reindented + "\n" + indent + normalizedText(argument: lastArgument)
                + "\n" + baseIndent + ")"
            )
        }

        private func correctSingleLine(
            arguments: [LabeledExprSyntax],
            callNode: FunctionCallExprSyntax
        ) -> ReasonedRuleViolation.ViolationCorrection? {
            guard
                let firstArgument = arguments.first,
                !shouldSuppressSingleLineCorrection(for: callNode),
                !arguments.contains(where: \.hasComments),
                let rightParen = callNode.rightParen
            else { return nil }

            let baseIndent = baseIndent(for: callNode)
            let indent = baseIndent + oneLevel

            let argLines = arguments.enumerated().map { index, arg -> String in
                let argText = normalizedText(argument: arg)
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .enumerated()
                    .map { $0.offset == 0 ? String($0.element) : oneLevel + $0.element }
                    .joined(separator: "\n")
                let needsComma = index < arguments.count - 1 && arg.trailingComma?.presence == .missing
                return indent + argText + (needsComma ? "," : "")
            }

            return ReasonedRuleViolation.ViolationCorrection(
                start: firstArgument.position,
                end: rightParen.endPositionBeforeTrailingTrivia,
                replacement: "\n" + (argLines + [baseIndent + ")"]).joined(separator: "\n")
            )
        }

        private var oneLevel: String {
            (CurrentRule.configuration?.indentation ?? .default).indentationString
        }

        private func endsWithClosingToken(argument: LabeledExprSyntax) -> Bool {
            guard let lastToken = argument.expression.lastToken(viewMode: .sourceAccurate) else { return false }
            return Self.closingTokensThatSkipNewlineAfterComma.contains(lastToken.tokenKind)
        }

        private func baseIndent(for callNode: FunctionCallExprSyntax) -> String {
            let lineNumber = line(for: callNode.positionAfterSkippingLeadingTrivia)
            guard lineNumber > 0, lineNumber <= file.lines.count else { return "" }
            return String(file.lines[lineNumber - 1].content.prefix(while: { $0.isWhitespace && $0 != "\r" }))
        }

        private func shouldSuppressSingleLineCorrection(for callNode: FunctionCallExprSyntax) -> Bool {
            var node = Syntax(callNode)
            var inArguments = false
            while let parent = node.parent {
                if parent.is(LabeledExprSyntax.self) || parent.is(LabeledExprListSyntax.self) {
                    inArguments = true
                } else if let outerCall = parent.as(FunctionCallExprSyntax.self), inArguments {
                    let outerArguments = Array(outerCall.arguments)
                    if outerArguments.count > 1 {
                        let outerPositions = outerArguments.map(\.positionAfterSkippingLeadingTrivia)
                        let firstLine = outerPositions.first.map { line(for: $0) } ?? 0
                        if outerPositions.allSatisfy({ line(for: $0) == firstLine }),
                           !outerArguments.contains(where: \.hasComments) {
                            if !configuration.allowsSingleLine {
                                return true
                            }
                            if let max = configuration.maxNumberOfSingleLineParameters,
                               outerPositions.count > max {
                                return true
                            }
                        }
                    }
                } else if inArguments {
                    break
                }
                node = parent
            }
            return false
        }

        private func startPosition(of argument: LabeledExprSyntax) -> AbsolutePosition {
            if let label = argument.label, label.presence != .missing {
                label.positionAfterSkippingLeadingTrivia
            } else {
                argument.expression.positionAfterSkippingLeadingTrivia
            }
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

private extension LabeledExprSyntax {
    var hasComments: Bool {
        tokens(viewMode: .sourceAccurate).contains { token in
            token.leadingTrivia.containsComments || token.trailingTrivia.containsComments
        }
    }
}

private extension FunctionCallExprSyntax {
    /// Returns `true` when this call (or a call containing this call) appears inside a
    /// pattern-matching pattern (`if case`, `switch case`, `for case`, `catch`),
    /// where SwiftSyntax wraps expressions in `ExpressionPatternSyntax`.
    /// Walks up through intermediate call/argument nodes to detect nesting.
    var isInPatternMatchingPatternPosition: Bool {
        var node = Syntax(self)
        while let parent = node.parent {
            if parent.is(ExpressionPatternSyntax.self) {
                return true
            }
            if parent.is(LabeledExprSyntax.self) || parent.is(LabeledExprListSyntax.self)
                || parent.is(FunctionCallExprSyntax.self) {
                node = parent
                continue
            }
            return false
        }
        return false
    }
}
