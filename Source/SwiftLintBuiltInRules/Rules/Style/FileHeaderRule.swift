import Foundation
import SourceKittenFramework
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct FileHeaderRule: Rule {
    var configuration = FileHeaderConfiguration()

    static let description = RuleDescription(
        identifier: "file_header",
        name: "File Header",
        description: "Header comments should be consistent with project patterns. " +
            "The SWIFTLINT_CURRENT_FILENAME placeholder can optionally be used in the " +
            "required and forbidden patterns. It will be replaced by the real file name.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let foo = \"Copyright\""),
            Example("let foo = 2 // Copyright"),
            Example("let foo = 2\n // Copyright"),
        ],
        triggeringExamples: [
            Example("// ↓Copyright"),
            Example("//\n// ↓Copyright"),
            Example("""
            //
            //  FileHeaderRule.swift
            //  SwiftLint
            //
            //  Created by Marcelo Fabri on 27/11/16.
            //  ↓Copyright © 2016 Realm. All rights reserved.
            //
            """),
        ].skipWrappingInCommentTests()
    )
}

private struct ProcessTriviaResult {
    let foundNonComment: Bool
}

private extension FileHeaderRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
            let headerRange = collectHeaderComments(from: node)

            let requiredRegex = configuration.requiredRegex(for: file)

            // If no header comments found
            guard let headerRange else {
                if requiredRegex != nil {
                    let violationPosition = node.shebang?.endPosition ?? node.position
                    violations.append(ReasonedRuleViolation(
                        position: violationPosition,
                        reason: requiredReason()
                    ))
                }
                return .skipChildren
            }

            // Extract header content
            guard let headerContent = extractHeaderContent(from: headerRange) else {
                return .skipChildren
            }

            // Check patterns
            checkForbiddenPattern(in: headerContent, startingAt: headerRange.start)
            checkRequiredPattern(requiredRegex, in: headerContent, startingAt: headerRange.start)

            return .skipChildren
        }

        private func collectHeaderComments(
            from node: SourceFileSyntax
        ) -> (start: AbsolutePosition, end: AbsolutePosition)? {
            var firstHeaderCommentStart: AbsolutePosition?
            var lastHeaderCommentEnd: AbsolutePosition?

            // Skip past shebang if present
            var currentPosition = node.position
            if let shebang = node.shebang {
                currentPosition = shebang.endPosition
            }

            // Collect header comments from tokens' trivia
            for token in node.tokens(viewMode: .sourceAccurate) {
                // Skip tokens before the start position (e.g., shebang)
                if token.endPosition <= currentPosition {
                    continue
                }

                let triviaResult = processTrivia(
                    token.leadingTrivia,
                    startingAt: &currentPosition,
                    firstStart: &firstHeaderCommentStart,
                    lastEnd: &lastHeaderCommentEnd
                )

                if triviaResult.foundNonComment || token.tokenKind != .endOfFile {
                    break
                }

                // Update current position past the token
                currentPosition = token.endPositionBeforeTrailingTrivia

                // Process trailing trivia if it's EOF
                if token.tokenKind == .endOfFile {
                    _ = processTrivia(token.trailingTrivia,
                                      startingAt: &currentPosition,
                                      firstStart: &firstHeaderCommentStart,
                                      lastEnd: &lastHeaderCommentEnd)
                }
            }

            guard let start = firstHeaderCommentStart,
                  let end = lastHeaderCommentEnd,
                  start < end else {
                return nil
            }

            return (start: start, end: end)
        }

        private func processTrivia(_ trivia: Trivia,
                                   startingAt currentPosition: inout AbsolutePosition,
                                   firstStart: inout AbsolutePosition?,
                                   lastEnd: inout AbsolutePosition?) -> ProcessTriviaResult {
            for piece in trivia {
                let pieceStart = currentPosition
                currentPosition += piece.sourceLength

                if isSwiftLintCommand(piece: piece) {
                    continue
                }

                if piece.isComment, !piece.isDocComment {
                    if firstStart == nil {
                        firstStart = pieceStart
                    }
                    lastEnd = currentPosition
                } else if !piece.isWhitespace {
                    return ProcessTriviaResult(foundNonComment: true)
                }
            }
            return ProcessTriviaResult(foundNonComment: false)
        }

        private func extractHeaderContent(from range: (start: AbsolutePosition, end: AbsolutePosition)) -> String? {
            let headerByteRange = ByteRange(
                location: ByteCount(range.start.utf8Offset),
                length: ByteCount(range.end.utf8Offset - range.start.utf8Offset)
            )

            return file.stringView.substringWithByteRange(headerByteRange)
        }

        private func checkForbiddenPattern(in headerContent: String, startingAt headerStart: AbsolutePosition) {
            guard
                let forbiddenRegex = configuration.forbiddenRegex(for: file),
                let firstMatch = forbiddenRegex.firstMatch(
                    in: headerContent,
                    options: [],
                    range: headerContent.fullNSRange
                )
            else {
                return
            }

            // Calculate violation position
            let matchLocationUTF16 = firstMatch.range.location
            let headerPrefix = String(headerContent.utf16.prefix(matchLocationUTF16)) ?? ""
            let utf8OffsetInHeader = headerPrefix.utf8.count
            let violationPosition = AbsolutePosition(utf8Offset: headerStart.utf8Offset + utf8OffsetInHeader)

            violations.append(ReasonedRuleViolation(
                position: violationPosition,
                reason: forbiddenReason()
            ))
        }

        private func checkRequiredPattern(_ requiredRegex: NSRegularExpression?,
                                          in headerContent: String,
                                          startingAt headerStart: AbsolutePosition) {
            guard
                let requiredRegex,
                requiredRegex.firstMatch(in: headerContent, options: [], range: headerContent.fullNSRange) == nil
            else {
                return
            }

            violations.append(ReasonedRuleViolation(
                position: headerStart,
                reason: requiredReason()
            ))
        }

        private func isSwiftLintCommand(piece: TriviaPiece) -> Bool {
            guard let text = piece.commentText else { return false }
            return text.contains("swiftlint:")
        }

        private func forbiddenReason() -> String {
            "Header comments should be consistent with project patterns"
        }

        private func requiredReason() -> String {
            "Header comments should be consistent with project patterns"
        }
    }
}

// Helper extensions
private extension TriviaPiece {
    var isDocComment: Bool {
        switch self {
        case .docLineComment, .docBlockComment:
            return true
        default:
            return false
        }
    }

    var commentText: String? {
        switch self {
        case .lineComment(let text), .blockComment(let text),
             .docLineComment(let text), .docBlockComment(let text):
            return text
        default:
            return nil
        }
    }
}
