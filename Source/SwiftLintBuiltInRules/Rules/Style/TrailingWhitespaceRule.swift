import Foundation
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true)
struct TrailingWhitespaceRule: Rule {
    var configuration = TrailingWhitespaceConfiguration()

    static let description = RuleDescription(
        identifier: "trailing_whitespace",
        name: "Trailing Whitespace",
        description: "Lines should not have trailing whitespace",
        kind: .style,
        nonTriggeringExamples: [
            Example("let name: String\n"), Example("//\n"), Example("// \n"),
            Example("let name: String //\n"), Example("let name: String // \n"),
        ],
        triggeringExamples: [
            Example("let name: String↓ \n"), Example("/* */ let name: String↓ \n")
        ],
        corrections: [
            Example("let name: String↓ \n"): Example("let name: String\n"),
            Example("/* */ let name: String↓ \n"): Example("/* */ let name: String\n"),
        ]
    )
}

private extension TrailingWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        // Pre-computed comment information for performance
        private var linesFullyCoveredByBlockComments = Set<Int>()
        private var linesEndingWithComment = Set<Int>()

        override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
            // Pre-compute all comment information in a single pass if needed
            if configuration.ignoresComments {
                precomputeCommentInformation(node)
            }

            // Process each line for trailing whitespace violations
            for lineContents in file.lines {
                let line = lineContents.content
                let lineNumber = lineContents.index // 1-based

                // Calculate trailing whitespace info
                guard let trailingWhitespaceInfo = line.trailingWhitespaceInfo() else {
                    continue // No trailing whitespace
                }

                // Apply `ignoresEmptyLines` configuration
                if configuration.ignoresEmptyLines, line.trimmingCharacters(in: .whitespaces).isEmpty {
                    continue
                }

                // Apply `ignoresComments` configuration
                if configuration.ignoresComments {
                    // Check if line is fully within a block comment
                    if linesFullyCoveredByBlockComments.contains(lineNumber) {
                        continue
                    }

                    // Check if line ends with a comment (using pre-computed info)
                    if linesEndingWithComment.contains(lineNumber) {
                        continue
                    }
                }

                // Calculate violation position
                let lineStartPos = locationConverter.position(ofLine: lineNumber, column: 1)
                let violationStartOffset = line.utf8.count - trailingWhitespaceInfo.byteLength
                let violationPosition = lineStartPos.advanced(by: violationStartOffset)

                let correctionEnd = lineStartPos.advanced(by: line.utf8.count)

                violations.append(ReasonedRuleViolation(
                    position: violationPosition,
                    correction: .init(start: violationPosition, end: correctionEnd, replacement: "")
                ))
            }
            return .skipChildren
        }

        /// Pre-computes all comment information in a single pass for better performance
        private func precomputeCommentInformation(_ node: SourceFileSyntax) {
            // First, collect block comment information
            collectLinesFullyCoveredByBlockComments(node)

            // Then, collect line comment ranges and determine which lines end with comments
            let lineCommentRanges = collectLineCommentRanges(from: node)
            determineLineEndingComments(using: lineCommentRanges)
        }

        /// Collects ranges of line comments organized by line number
        private func collectLineCommentRanges(from node: SourceFileSyntax) -> [Int: [Range<AbsolutePosition>]] {
            var lineCommentRanges: [Int: [Range<AbsolutePosition>]] = [:]

            for token in node.tokens(viewMode: .sourceAccurate) {
                // Process leading trivia
                var currentPos = token.position
                for piece in token.leadingTrivia {
                    let pieceStart = currentPos
                    currentPos += piece.sourceLength

                    if piece.isComment, !piece.isBlockComment {
                        let pieceStartLine = locationConverter.location(for: pieceStart).line
                        lineCommentRanges[pieceStartLine, default: []].append(pieceStart..<currentPos)
                    }
                }

                // Process trailing trivia
                currentPos = token.endPositionBeforeTrailingTrivia
                for piece in token.trailingTrivia {
                    let pieceStart = currentPos
                    currentPos += piece.sourceLength

                    if piece.isComment, !piece.isBlockComment {
                        let pieceStartLine = locationConverter.location(for: pieceStart).line
                        lineCommentRanges[pieceStartLine, default: []].append(pieceStart..<currentPos)
                    }
                }
            }

            return lineCommentRanges
        }

        /// Determines which lines end with comments based on line comment ranges
        private func determineLineEndingComments(using lineCommentRanges: [Int: [Range<AbsolutePosition>]]) {
            for lineNumber in 1...file.lines.count {
                let line = file.lines[lineNumber - 1].content

                // Skip if no trailing whitespace
                guard let trailingWhitespaceInfo = line.trailingWhitespaceInfo() else {
                    continue
                }

                // Get the effective content (before trailing whitespace)
                let effectiveContent = getEffectiveContent(from: line, removing: trailingWhitespaceInfo)

                // Check if the effective content ends with a comment
                if checkIfContentEndsWithComment(
                    effectiveContent,
                    lineNumber: lineNumber,
                    lineCommentRanges: lineCommentRanges
                ) {
                    linesEndingWithComment.insert(lineNumber)
                }
            }
        }

        /// Gets the content of a line before its trailing whitespace
        private func getEffectiveContent(
            from line: String,
            removing trailingWhitespaceInfo: TrailingWhitespaceInfo
        ) -> String {
            if trailingWhitespaceInfo.characterCount > 0, line.count >= trailingWhitespaceInfo.characterCount {
                return String(line.prefix(line.count - trailingWhitespaceInfo.characterCount))
            }
            return ""
        }

        /// Checks if the given content ends with a comment
        private func checkIfContentEndsWithComment(
            _ effectiveContent: String,
            lineNumber: Int,
            lineCommentRanges: [Int: [Range<AbsolutePosition>]]
        ) -> Bool {
            guard !effectiveContent.isEmpty,
                  let lastNonWhitespaceIdx = effectiveContent.lastIndex(where: { !$0.isWhitespace }) else {
                return false
            }

            // Calculate the byte position of the last non-whitespace character
            let contentUpToLastChar = effectiveContent.prefix(through: lastNonWhitespaceIdx)
            let byteOffsetToLastChar = contentUpToLastChar.utf8.count - 1 // -1 for position of char
            let lineStartPos = locationConverter.position(ofLine: lineNumber, column: 1)
            let lastNonWhitespacePos = lineStartPos.advanced(by: byteOffsetToLastChar)

            // Check if this position falls within any comment range on this line
            if let ranges = lineCommentRanges[lineNumber] {
                for range in ranges {
                    if range.lowerBound <= lastNonWhitespacePos, lastNonWhitespacePos < range.upperBound {
                        return true
                    }
                }
            }

            return false
        }

        /// Collects line numbers that are fully covered by block comments
        private func collectLinesFullyCoveredByBlockComments(_ sourceFile: SourceFileSyntax) {
            for token in sourceFile.tokens(viewMode: .sourceAccurate) {
                var currentPos = token.position

                // Process leading trivia
                for piece in token.leadingTrivia {
                    let pieceStartPos = currentPos
                    currentPos += piece.sourceLength

                    if piece.isBlockComment {
                        markLinesFullyCoveredByBlockComment(
                            blockCommentStart: pieceStartPos,
                            blockCommentEnd: currentPos
                        )
                    }
                }

                // Advance past token content
                currentPos = token.endPositionBeforeTrailingTrivia

                // Process trailing trivia
                for piece in token.trailingTrivia {
                    let pieceStartPos = currentPos
                    currentPos += piece.sourceLength

                    if piece.isBlockComment {
                        markLinesFullyCoveredByBlockComment(
                            blockCommentStart: pieceStartPos,
                            blockCommentEnd: currentPos
                        )
                    }
                }
            }
        }

        /// Marks lines that are fully covered by a block comment
        private func markLinesFullyCoveredByBlockComment(
            blockCommentStart: AbsolutePosition,
            blockCommentEnd: AbsolutePosition
        ) {
            let startLocation = locationConverter.location(for: blockCommentStart)
            let endLocation = locationConverter.location(for: blockCommentEnd)

            let startLine = startLocation.line
            var endLine = endLocation.line

            // If comment ends at column 1, it actually ended on the previous line
            if endLocation.column == 1, endLine > startLine {
                endLine -= 1
            }

            for lineNum in startLine...endLine {
                if lineNum <= 0 || lineNum > file.lines.count { continue }

                let lineInfo = file.lines[lineNum - 1]
                let lineContent = lineInfo.content
                let lineStartPos = locationConverter.position(ofLine: lineNum, column: 1)

                // Check if the line's non-whitespace content is fully within the block comment
                if let firstNonWhitespaceIdx = lineContent.firstIndex(where: { !$0.isWhitespace }),
                   let lastNonWhitespaceIdx = lineContent.lastIndex(where: { !$0.isWhitespace }) {
                    // Line has non-whitespace content
                    // Calculate byte offsets (not character offsets) for AbsolutePosition
                    let contentBeforeFirstNonWS = lineContent.prefix(upTo: firstNonWhitespaceIdx)
                    let byteOffsetToFirstNonWS = contentBeforeFirstNonWS.utf8.count
                    let firstNonWhitespacePos = lineStartPos.advanced(by: byteOffsetToFirstNonWS)

                    let contentBeforeLastNonWS = lineContent.prefix(upTo: lastNonWhitespaceIdx)
                    let byteOffsetToLastNonWS = contentBeforeLastNonWS.utf8.count
                    let lastNonWhitespacePos = lineStartPos.advanced(by: byteOffsetToLastNonWS)

                    // Check if both first and last non-whitespace positions are within the comment
                    if firstNonWhitespacePos >= blockCommentStart, lastNonWhitespacePos < blockCommentEnd {
                        linesFullyCoveredByBlockComments.insert(lineNum)
                    }
                } else {
                    // Line is all whitespace - check if it's within the comment bounds
                    let lineEndPos = lineStartPos.advanced(by: lineContent.utf8.count)
                    if lineStartPos >= blockCommentStart, lineEndPos <= blockCommentEnd {
                        linesFullyCoveredByBlockComments.insert(lineNum)
                    }
                }
            }
        }
    }
}

// Helper struct to return both character count and byte length for whitespace
private struct TrailingWhitespaceInfo {
    let characterCount: Int
    let byteLength: Int
}

private extension String {
    func hasTrailingWhitespace() -> Bool {
        if isEmpty { return false }
        guard let lastScalar = unicodeScalars.last else { return false }
        return CharacterSet.whitespaces.contains(lastScalar)
    }

    /// Returns information about trailing whitespace (spaces and tabs only)
    func trailingWhitespaceInfo() -> TrailingWhitespaceInfo? {
        var charCount = 0
        var byteLen = 0
        for char in self.reversed() {
            if char.isWhitespace, char == " " || char == "\t" { // Only count spaces and tabs
                charCount += 1
                byteLen += char.utf8.count
            } else {
                break
            }
        }
        return charCount > 0 ? TrailingWhitespaceInfo(characterCount: charCount, byteLength: byteLen) : nil
    }

    func trimmingTrailingCharacters(in characterSet: CharacterSet) -> String {
        var end = endIndex
        while end > startIndex {
            let index = index(before: end)
            if !characterSet.contains(self[index].unicodeScalars.first!) {
                break
            }
            end = index
        }
        return String(self[..<end])
    }
}

private extension TriviaPiece {
    var isBlockComment: Bool {
        switch self {
        case .blockComment, .docBlockComment:
            return true
        default:
            return false
        }
    }
}
