import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct MultilineCallArgumentsRule: Rule {
    /// Configuration for the multiline_call_arguments rule.
    var configuration = MultilineCallArgumentsConfiguration()

    /// Reasons for violations reported by this rule.
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
        when arguments are split across lines; optionally limits or forbids multi-argument \
        single-line calls via configuration.
        """,
        rationale: """
        Keeping each argument on its own line in multi-line calls improves readability and \
        reduces merge conflicts. Requiring a newline after commas makes the call's structure \
        immediately visible and avoids ambiguous layouts where arguments appear to share a line.

        ## Configuration

        - `allows_single_line`: Allow calls with multiple arguments on a single line \
        (default: `true`)
        - `max_number_of_single_line_parameters`: Max arguments allowed on a single line \
        (default: `nil` — unlimited)
        - `indentation`: Indentation width for corrected lines \
        (integer for spaces, e.g. `4`, `2`, `8`; or the string `"tab"`); \
        `0` and negative values are invalid and will cause a configuration error

        ## Behavior details

        - When `allows_single_line: false`, any call with 2+ arguments on one line triggers \
        a violation
        - Setting `allows_single_line: false` with `max_number_of_single_line_parameters > 1` \
        is invalid and will cause a configuration error; \
        `max_number_of_single_line_parameters: 1` is allowed
        - `max_number_of_single_line_parameters` only affects single-line calls; \
        in multi-line calls each argument must always start on its own line
        - Both labeled and unlabeled (positional) arguments are subject to the same rules

        ## Auto-correction

        - Single-line calls are reformatted to place each argument on its own line with proper \
        indentation; the closing parenthesis moves to its own line at the call's base indent
        - Indentation is calculated relative to the call's start line; exactly one level of \
        configured indentation is applied from the call's base indent, regardless of nesting \
        depth (e.g., `foo(bar(baz(1, 2)))` corrects each call independently, compounding the \
        indent)
        - When a single-line call is nested in the arguments of another single-line call that \
        also violates this rule, only the outer call's auto-correction is applied; the inner \
        call is corrected on a subsequent `--fix` pass to avoid overlapping edits
        - Calls with comments in argument tokens will not be auto-corrected (manual fix required)
        - Auto-correction does not reformat the internal content of arguments (e.g., closures, \
        array literals); the closing delimiter of such expressions may end up on its own line \
        after the split, requiring a subsequent manual adjustment

        ## Skipped cases

        - When an argument's expression ends with `}` or `]` (e.g., a closure or array literal), \
        the comma-newline check is skipped — the argument is considered properly terminated
        - Pattern-matching positions (`if case let`, `switch case`, `for case let`, `catch`) \
        are excluded; enum-case constructor calls are linted as normal function calls
        """,
        kind: .style,
        nonTriggeringExamples: MultilineCallArgumentsRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineCallArgumentsRuleExamples.triggeringExamples,
        corrections: MultilineCallArgumentsRuleExamples.corrections
    )
}

private extension MultilineCallArgumentsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        /// Cache mapping position offsets to line numbers for performance.
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

            let arguments = Array(node.arguments)
            guard arguments.count > 1 else { return }

            let argumentPositions = arguments.map(\.positionAfterSkippingLeadingTrivia)
            violations.append(
                contentsOf: reasonedViolations(
                    argumentPositions: argumentPositions,
                    arguments: arguments,
                    callNode: node
                )
            )
        }

        /// Determines violations for a function call: single-line violations (too many
        /// arguments, or `allows_single_line: false`) take priority; for multi-line calls,
        /// both duplicate-start-line and missing-newline-after-comma violations are collected.
        private func reasonedViolations(
            argumentPositions: [AbsolutePosition],
            arguments: [LabeledExprSyntax],
            callNode: FunctionCallExprSyntax
        ) -> [ReasonedRuleViolation] {
            guard let firstPosition = argumentPositions.first else { return [] }

            let firstLine = line(for: firstPosition)
            let allOnSameLine = argumentPositions.allSatisfy { line(for: $0) == firstLine }

            if allOnSameLine {
                if !configuration.allowsSingleLine {
                    let violation = ReasonedRuleViolation(
                        position: argumentPositions[1],
                        reason: Reason.singleLineMultipleArgumentsNotAllowed,
                        correction: singleLineCorrection(
                            arguments: arguments,
                            callNode: callNode
                        )
                    )
                    return [violation]
                }

                if let max = configuration.maxNumberOfSingleLineParameters,
                   argumentPositions.count > max {
                    let violation = ReasonedRuleViolation(
                        position: argumentPositions[max],
                        reason: Reason.tooManyArgumentsOnSingleLine(max: max),
                        correction: singleLineCorrection(
                            arguments: arguments,
                            callNode: callNode
                        )
                    )
                    return [violation]
                }

                return []
            }

            var result: [ReasonedRuleViolation] = []
            result.append(contentsOf: duplicateArgumentStartLineViolations(arguments: arguments, callNode: callNode))
            result.append(contentsOf: newlineAfterCommaViolations(arguments: arguments, callNode: callNode))
            return result
        }

        private func duplicateArgumentStartLineViolations(
            arguments: [LabeledExprSyntax],
            callNode: FunctionCallExprSyntax
        ) -> [ReasonedRuleViolation] {
            var seen: Set<Int> = []
            var result: [ReasonedRuleViolation] = []
            for (index, argument) in arguments.enumerated() {
                let startPosition = startPosition(of: argument)
                let argumentLine = line(for: startPosition)
                if !seen.insert(argumentLine).inserted {
                    let prevArgument = arguments[index - 1]
                    let correctionStart: AbsolutePosition
                    if let comma = prevArgument.trailingComma, comma.presence != .missing {
                        correctionStart = comma.endPositionBeforeTrailingTrivia
                    } else {
                        correctionStart = prevArgument.endPositionBeforeTrailingTrivia
                    }

                    let correction: ReasonedRuleViolation.ViolationCorrection? = hasComments(arguments: arguments)
                    ? nil
                    : newlineAndIndentCorrection(
                        start: correctionStart,
                        end: startPosition,
                        callNode: callNode
                    )

                    result.append(
                        ReasonedRuleViolation(
                            position: startPosition,
                            reason: Reason.eachArgumentMustStartOnOwnLine,
                            correction: correction
                        )
                    )
                }
            }
            return result
        }

        private func newlineAfterCommaViolations(
            arguments: [LabeledExprSyntax],
            callNode: FunctionCallExprSyntax
        ) -> [ReasonedRuleViolation] {
            var result: [ReasonedRuleViolation] = []
            for index in arguments.indices.dropLast() {
                let current = arguments[index]
                let next = arguments[index + 1]

                guard let comma = current.trailingComma, comma.presence != .missing else { continue }

                // Skip if expression ends with closing brace/bracket (already properly terminated)
                if let lastToken = current.expression.lastToken(viewMode: .sourceAccurate),
                   [.rightBrace, .rightSquare].contains(lastToken.tokenKind) {
                    continue
                }

                let commaLine = line(for: comma.positionAfterSkippingLeadingTrivia)
                let currentStartLine = line(for: startPosition(of: current))
                let nextStartPosition = startPosition(of: next)
                let nextStartLine = line(for: nextStartPosition)

                // Comma and next arg share a line, but current arg started on a different line
                // → the comma-newline split is missing (e.g., `}, b: 3` after a multiline arg)
                if commaLine == nextStartLine, currentStartLine != nextStartLine {
                    let correction: ReasonedRuleViolation.ViolationCorrection? = hasComments(arguments: arguments)
                    ? nil
                    : newlineAndIndentCorrection(
                        start: comma.endPositionBeforeTrailingTrivia,
                        end: nextStartPosition,
                        callNode: callNode
                    )

                    result.append(
                        ReasonedRuleViolation(
                            position: nextStartPosition,
                            reason: Reason.newlineRequiredAfterCommaInMultilineCall,
                            correction: correction
                        )
                    )
                }
            }
            return result
        }

        /// Returns the indentation string for argument lines: the call's base indent
        /// plus one level of configured indentation.
        private func argumentIndent(for callNode: FunctionCallExprSyntax) -> String {
            let callStartLine = line(for: callNode.positionAfterSkippingLeadingTrivia)
            let baseIndent = getLineIndent(lineNumber: callStartLine)
            return baseIndent + configuration.indentationStyle.indentationString
        }

        private func newlineAndIndentCorrection(
            start: AbsolutePosition,
            end: AbsolutePosition,
            callNode: FunctionCallExprSyntax
        ) -> ReasonedRuleViolation.ViolationCorrection {
            let indent = argumentIndent(for: callNode)

            return ReasonedRuleViolation.ViolationCorrection(
                start: start,
                end: end,
                replacement: "\n" + indent
            )
        }

        /// Produces a correction that reformats a single-line call into multi-line form:
        /// each argument on its own line with proper indentation, closing `)` on a separate
        /// line at the call's base indent. Returns `nil` when comments are present or the
        /// call is nested inside another single-line correction (overlap guard).
        private func singleLineCorrection(
            arguments: [LabeledExprSyntax],
            callNode: FunctionCallExprSyntax
        ) -> ReasonedRuleViolation.ViolationCorrection? {
            guard let firstArgument = arguments.first else { return nil }

            guard !shouldSuppressSingleLineCorrection(for: callNode) else { return nil }
            guard !hasComments(arguments: arguments) else { return nil }
            guard let rightParen = callNode.rightParen else { return nil }

            let indent = argumentIndent(for: callNode)
            let callStartLine = line(for: callNode.positionAfterSkippingLeadingTrivia)
            let baseIndent = getLineIndent(lineNumber: callStartLine)

            let argLines = arguments.enumerated().map { index, arg -> String in
                let argText = arg.description.trimmingCharacters(in: .whitespacesAndNewlines)
                // Only fires during error recovery (e.g., `foo(a: 1 b: 2)`);
                // in valid Swift, non-last arguments always have a trailing comma.
                let needsComma = index < arguments.count - 1 && arg.trailingComma?.presence == .missing
                let suffix = needsComma ? "," : ""
                return indent + argText + suffix
            }

            let replacement = "\n" + (argLines + [baseIndent + ")"]).joined(separator: "\n")

            return .init(
                start: firstArgument.position,
                end: rightParen.endPositionBeforeTrailingTrivia,
                replacement: replacement
            )
        }

        /// Suppresses `singleLineCorrection` for a call nested in the arguments of another
        /// single-line call that would also produce a `singleLineCorrection`, because the
        /// outer correction encompasses the inner one. Without this guard, overlapping
        /// `replaceSubrange` calls in the framework would silently corrupt the output.
        ///
        /// Walks up the entire parent chain — an intermediate non-violating call (e.g., a
        /// 1-arg wrapper) does NOT suppress the inner call, but a higher ancestor that
        /// does violate WILL. Returns `true` only when a qualifying outer call is found.
        private func shouldSuppressSingleLineCorrection(for callNode: FunctionCallExprSyntax) -> Bool {
            var node = Syntax(callNode)
            var inArguments = false
            while let parent = node.parent {
                if parent.is(LabeledExprSyntax.self) || parent.is(LabeledExprListSyntax.self) {
                    inArguments = true
                }
                if let outerCall = parent.as(FunctionCallExprSyntax.self), inArguments {
                    let outerArguments = Array(outerCall.arguments)
                    if outerArguments.count > 1 {
                        let outerPositions = outerArguments.map(\.positionAfterSkippingLeadingTrivia)
                        let firstLine = outerPositions.first.map { line(for: $0) } ?? 0
                        if outerPositions.allSatisfy({ line(for: $0) == firstLine }) {
                            if !configuration.allowsSingleLine, !hasComments(arguments: outerArguments) {
                                return true
                            }
                            if let max = configuration.maxNumberOfSingleLineParameters,
                               outerPositions.count > max, !hasComments(arguments: outerArguments) {
                                return true
                            }
                        }
                    }
                }
                node = parent
            }
            return false
        }

        private func hasComments(arguments: [LabeledExprSyntax]) -> Bool {
            arguments.contains { argument in
                argument.tokens(viewMode: .sourceAccurate).contains { token in
                    token.leadingTrivia.containsComments || token.trailingTrivia.containsComments
                }
            }
        }

        /// Extracts the leading whitespace (indentation) from a line.
        /// Used to preserve existing indentation when adding new lines.
        private func getLineIndent(lineNumber: Int) -> String {
            guard lineNumber > 0, lineNumber <= file.lines.count else {
                return ""
            }
            let lineContent = file.lines[lineNumber - 1].content
            let leadingWhitespace = lineContent.prefix(while: { $0.isWhitespace && $0 != "\r" })
            return String(leadingWhitespace)
        }

        /// Returns the start position of an argument, preferring label over expression.
        /// This ensures consistent position calculation for both labeled and unlabeled arguments.
        private func startPosition(of argument: LabeledExprSyntax) -> AbsolutePosition {
            if let label = argument.label, label.presence != .missing {
                return label.positionAfterSkippingLeadingTrivia
            }
            return argument.expression.positionAfterSkippingLeadingTrivia
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

private extension FunctionCallExprSyntax {
    /// Returns `true` if this call appears in a pattern position (e.g., `case .foo(a)`).
    ///
    /// Works because SwiftSyntax wraps pattern expressions in `ExpressionPatternSyntax`:
    /// - `if case let .foo(a) = x` → parent is ExpressionPatternSyntax
    /// - `switch x { case let .foo(a): }` → parent is ExpressionPatternSyntax
    /// - `for case let .foo(a) in items` → parent is ExpressionPatternSyntax
    /// - `catch .foo(1, 2)` → parent is ExpressionPatternSyntax
    var isInPatternMatchingPatternPosition: Bool {
        parent?.is(ExpressionPatternSyntax.self) == true
    }
}
