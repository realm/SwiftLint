import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct OrphanedDocCommentRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "orphaned_doc_comment",
        name: "Orphaned Doc Comment",
        description: "A doc comment should be attached to a declaration",
        kind: .lint,
        nonTriggeringExamples: #examples([
            """
            /// My great property
            var myGreatProperty: String!
            """,
            """
            //////////////////////////////////////
            //
            // Copyright header.
            //
            //////////////////////////////////////
            """,
            """
            /// Look here for more info: https://github.com.
            var myGreatProperty: String!
            """,
            """
            /// Look here for more info:
            /// https://github.com.
            var myGreatProperty: String!
            """,
            """
            /// My great property
            // Not a doc string
            var myGreatProperty: String!
            """,
            """
            /// Look here for more info: https://github.com.
            // Not a doc string
            var myGreatProperty: String!
            """,
            """
            /// Look here for more info: https://github.com.


            // Not a doc string
            var myGreatProperty: String!
            """,
            """
            /// Look here for more info: https://github.com.
            // Not a doc string
            /// My great property
            // Not a doc string
            var myGreatProperty: String!
            """,
            """
            extension Nested {
                ///
                /// Look here for more info: https://github.com.

                // Not a doc string
                var myGreatProperty: String!
            }
            """,
        ]),
        triggeringExamples: #examples([
            """
            ↓/// My great property

            /// Documentation that is attached to the declaration.
            var myGreatProperty: String!
            """,
            """
            ↓/// Look here for more info: https://github.com.

            /// Documentation that is attached to the declaration.
            var myGreatProperty: String!
            """,
            """
            ↓/// Look here for more info: https://github.com.


            /// Documentation that is attached to the declaration.
            var myGreatProperty: String!
            """,
            """
            ↓/// Look here for more info: https://github.com.
            ↓/// More orphaned documentation.

            /// Documentation that is attached to the declaration.
            var myGreatProperty: String!
            """,
            """
            extension Nested {
                ↓///
                ↓/// Look here for more info: https://github.com.

                /// Documentation that is attached to the declaration.
                var myGreatProperty: String!
            }
            """,
            """
            ↓/// Documentation without a declaration.
            """,
        ])
    )
}

private extension OrphanedDocCommentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TokenSyntax) {
            let pieces = node.leadingTrivia.pieces
            for offset in orphanedDocCommentOffsets(in: pieces, isEndOfFile: node.tokenKind == .endOfFile) {
                violations.append(node.position.advanced(by: offset))
            }
        }
    }
}

private func orphanedDocCommentOffsets(in pieces: [TriviaPiece], isEndOfFile: Bool) -> [Int] {
    var pendingDocCommentOffsets: [Int] = []
    var orphanedDocCommentOffsets: [Int] = []
    var utf8Offset = 0
    var currentLine = 1
    var previousCommentEndLine: Int?

    for piece in pieces {
        defer {
            utf8Offset += piece.sourceLength.utf8Length
            currentLine += piece.lineBreakCount
        }

        switch piece {
        case .docLineComment(let comment), .docBlockComment(let comment):
            // These patterns are often used for "file header" style comments.
            guard !comment.hasPrefix("////"), !comment.hasPrefix("/***") else {
                continue
            }

        case .lineComment, .blockComment:
            previousCommentEndLine = currentLine + piece.lineBreakCount

        default:
            continue
        }

        guard piece.isDocComment else {
            continue
        }

        if let previousCommentEndLine,
           !pendingDocCommentOffsets.isEmpty,
           currentLine > previousCommentEndLine + 1 {
            orphanedDocCommentOffsets.append(contentsOf: pendingDocCommentOffsets)
            pendingDocCommentOffsets.removeAll()
        }

        pendingDocCommentOffsets.append(utf8Offset)
        previousCommentEndLine = currentLine + piece.lineBreakCount
    }

    if isEndOfFile {
        orphanedDocCommentOffsets.append(contentsOf: pendingDocCommentOffsets)
    }

    return orphanedDocCommentOffsets
}

private extension TriviaPiece {
    var isDocComment: Bool {
        switch self {
        case .docLineComment, .docBlockComment:
            return true
        default:
            return false
        }
    }

    var lineBreakCount: Int {
        switch self {
        case .carriageReturnLineFeeds(let count), .carriageReturns(let count), .newlines(let count):
            count
        case .blockComment(let comment), .docBlockComment(let comment),
             .lineComment(let comment), .docLineComment(let comment),
             .unexpectedText(let comment):
            comment.reduce(0) { count, character in
                count + (character.isNewline ? 1 : 0)
            }
        default:
            0
        }
    }
}
