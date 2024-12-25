import Foundation
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct MarkRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "mark",
        name: "Mark",
        description: "MARK comment should be in valid format. e.g. '// MARK: ...' or '// MARK: - ...'",
        kind: .lint,
        nonTriggeringExamples: MarkRuleExamples.nonTriggeringExamples,
        triggeringExamples: MarkRuleExamples.triggeringExamples,
        corrections: MarkRuleExamples.corrections
    )
}

private extension MarkRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TokenSyntax) {
            for result in node.violationResults() {
                violations.append(result.position)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ token: TokenSyntax) -> TokenSyntax {
            var pieces = token.leadingTrivia.pieces
            for result in token.violationResults() {
                // caution: `correctionPositions` records the positions before the mutations.
                // https://github.com/realm/SwiftLint/pull/4297
                correctionPositions.append(result.position)
                result.correct(&pieces)
            }
            return super.visit(token.with(\.leadingTrivia, Trivia(pieces: pieces)))
        }
    }
}

private struct ViolationResult {
    let position: AbsolutePosition
    let correct: (inout [TriviaPiece]) -> Void
}

private extension TokenSyntax {
    private enum Mark {
        static func lint(in text: String) -> [() -> String] {
            regex(badPattern).matches(in: text, options: [], range: text.fullNSRange).compactMap { match in
                isIgnoredCases(text, range: match.range) ? nil : {
                    var corrected = replace(text, range: match.range(at: 2), to: "- ")
                    corrected = replace(corrected, range: match.range(at: 1), to: "// MARK: ")
                    if !text.hasSuffix(" "), corrected.hasSuffix(" ") {
                        corrected.removeLast()
                    }
                    return corrected
                }
            }
        }

        private static func isIgnoredCases(_ text: String, range: NSRange) -> Bool {
            range.lowerBound != 0 || regex(goodPattern).firstMatch(in: text, range: text.fullNSRange) != nil
        }

        private static let goodPattern = [
            "^// MARK: \(oneOrMoreHyphen) \(anyText)$",
            "^// MARK: \(oneOrMoreHyphen) ?$",
            "^// MARK: \(nonSpaceOrHyphen)+ ?\(anyText)?$",
            "^// MARK:$",

            // comment start with `Mark ...` is ignored
            "^\(twoOrThreeSlashes) +[Mm]ark[^:]",
        ].map(nonCapturingGroup).joined(separator: "|")

        private static let badPattern = capturingGroup([
            "MARK[^\\s:]",
            "[Mm]ark",
            "MARK",
        ].map(basePattern).joined(separator: "|")) + capturingGroup(hyphenOrEmpty)

        private static let anySpace = " *"
        private static let nonSpaceOrTwoOrMoreSpace = "(?: {2,})?"

        private static let anyText = "(?:\\S.*)"

        private static let oneOrMoreHyphen = "-+"
        private static let nonSpaceOrHyphen = "[^ -]"

        private static let twoOrThreeSlashes = "///?"
        private static let colonOrEmpty = ":?"
        private static let hyphenOrEmpty = "-? *"

        private static func nonCapturingGroup(_ pattern: String) -> String {
            "(?:\(pattern))"
        }

        private static func capturingGroup(_ pattern: String) -> String {
            "(\(pattern))"
        }

        private static func basePattern(_ pattern: String) -> String {
            nonCapturingGroup("\(twoOrThreeSlashes)\(anySpace)\(pattern)\(anySpace)\(colonOrEmpty)\(anySpace)")
        }

        private static func replace(_ target: String, range nsrange: NSRange, to replaceString: String) -> String {
            guard nsrange.length > 0, let range = Range(nsrange, in: target) else {
                return target
            }
            return target.replacingCharacters(in: range, with: replaceString)
        }
    }

    func violationResults() -> [ViolationResult] {
        var utf8Offset = 0
        var results: [ViolationResult] = []

        for index in leadingTrivia.pieces.indices {
            let piece = leadingTrivia.pieces[index]
            defer { utf8Offset += piece.sourceLength.utf8Length }

            switch piece {
            case .lineComment(let comment), .docLineComment(let comment):
                for correct in Mark.lint(in: comment) {
                    let position = position.advanced(by: utf8Offset)
                    results.append(ViolationResult(position: position) { pieces in
                        pieces[index] = .lineComment(correct())
                    })
                }

            default:
                break
            }
        }

        return results
    }
}
