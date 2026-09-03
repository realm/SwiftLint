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
        ]),
        triggeringExamples: #examples([
            """
            ↓/// My great property
            // Not a doc string
            var myGreatProperty: String!
            """,
            """
            ↓/// Look here for more info: https://github.com.
            // Not a doc string
            var myGreatProperty: String!
            """,
            """
            ↓/// The #2989 motivation.
            // swiftlint:disable:next force_unwrapping
            public var caseD: String! = nil
            """,
            """
            ↓/// Look here for more info: https://github.com.


            // Not a doc string
            var myGreatProperty: String!
            """,
            """
            ↓/// Look here for more info: https://github.com.
            // Not a doc string
            ↓/// My great property
            // Not a doc string
            var myGreatProperty: String!
            """,
            """
            extension Nested {
                ↓///
                /// Look here for more info: https://github.com.

                // Not a doc string
                var myGreatProperty: String!
            }
            """,
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
            /// More orphaned documentation.

            /// Documentation that is attached to the declaration.
            var myGreatProperty: String!
            """,
            """
            extension Nested {
                ↓///
                /// Look here for more info: https://github.com.

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
    var pendingDocCommentOffset: Int?
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
            if let offset = pendingDocCommentOffset {
                orphanedDocCommentOffsets.append(offset)
                pendingDocCommentOffset = nil
            }
            previousCommentEndLine = currentLine + piece.lineBreakCount
            continue

        default:
            continue
        }

        if let previousCommentEndLine,
           pendingDocCommentOffset != nil,
           currentLine > previousCommentEndLine + 1 {
            if let offset = pendingDocCommentOffset {
                orphanedDocCommentOffsets.append(offset)
                pendingDocCommentOffset = nil
            }
        }

        pendingDocCommentOffset = pendingDocCommentOffset ?? utf8Offset
        previousCommentEndLine = currentLine + piece.lineBreakCount
    }

    if isEndOfFile, let pendingDocCommentOffset {
        orphanedDocCommentOffsets.append(pendingDocCommentOffset)
    }

    return orphanedDocCommentOffsets
}

private extension TriviaPiece {
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
