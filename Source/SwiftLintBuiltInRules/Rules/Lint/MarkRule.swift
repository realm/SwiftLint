import Foundation
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct MarkRule: CorrectableRule {
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
        override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
            for result in token.violationResults() {
                violations.append(result.position)
            }
            return .skipChildren
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        private var correctedPositions: Set<AbsolutePosition> = []

        override func visit(_ token: TokenSyntax) -> TokenSyntax {
            var newToken = token

            var pieces = newToken.leadingTrivia.pieces
            for result in newToken.violationResults(withCorrect: true) {
                correctionPositions.append(result.position)
                result.correct?(&pieces)
            }

            if pieces != newToken.leadingTrivia.pieces {
                newToken.leadingTrivia = .init(pieces: pieces)
            }
            return super.visit(newToken)
        }
    }
}

private struct ViolationResult {
    var position: AbsolutePosition
    var correct: ((inout [TriviaPiece]) -> Void)?
}

private extension TokenSyntax {
    private enum Mark {
        static func lint(in text: String) -> [() -> String] {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            return regex(badPattern).matches(in: text, options: [], range: range).compactMap { match in
                isIgnoredCases(text, range: range) ? nil : {
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
            regex(goodPattern).firstMatch(in: text, range: range) != nil
        }

        private static let goodPattern = [
            "^// MARK: \(oneOrMoreHyphen) \(anyText)$",
            "^// MARK: \(oneOrMoreHyphen) ?$",
            "^// MARK: \(nonSpaceOrHyphen)+ ?\(anyText)?$",
            "^// MARK:$",

            // comment start with `Mark ...` is ignored
            "^\(twoOrThreeSlashes) +[Mm]ark[^:]"
        ].map(nonCapturingGroup).joined(separator: "|")

        private static let badPattern = capturingGroup([
            "MARK[^\\s:]",
            "[Mm]ark",
            "MARK"
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

    func violationResults(withCorrect: Bool = false) -> [ViolationResult] {
        var utf8Offset = 0
        var results: [ViolationResult] = []

        for index in leadingTrivia.pieces.indices {
            var piece = leadingTrivia.pieces[index]
            defer { utf8Offset += piece.sourceLength.utf8Length }

            switch piece {
            case .lineComment(let comment), .docLineComment(let comment):
                for correct in Mark.lint(in: comment) {
                    let position = position.advanced(by: utf8Offset)
                    if withCorrect {
                        let corrected = correct()
                        piece = .lineComment(corrected)
                        results.append(ViolationResult(position: position) { pieces in
                            pieces[index] = piece
                        })
                    } else {
                        results.append(ViolationResult(position: position))
                    }
                }

            default:
                break
            }
        }

        return results
    }
}
