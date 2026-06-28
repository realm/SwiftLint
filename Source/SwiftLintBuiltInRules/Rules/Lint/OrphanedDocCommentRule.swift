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
        ])
    )
}

private extension OrphanedDocCommentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TokenSyntax) {
            let pieces = node.leadingTrivia.pieces
            var iterator = pieces.enumerated().makeIterator()
            while let (index, piece) = iterator.next() {
                switch piece {
                case .docLineComment(let comment), .docBlockComment(let comment):
                    // These patterns are often used for "file header" style comments
                    if !comment.hasPrefix("////"), !comment.hasPrefix("/***") {
                        if isOrphanedDocComment(with: &iterator) {
                            let utf8Length = pieces[..<index].reduce(0) { $0 + $1.sourceLength.utf8Length }
                            violations.append(node.position.advanced(by: utf8Length))
                        }
                    }

                default:
                    break
                }
            }
        }
    }
}

private func isOrphanedDocComment(
    with iterator: inout some IteratorProtocol<(offset: Int, element: TriviaPiece)>
) -> Bool {
    while let (_, piece) = iterator.next() {
        switch piece {
        case .docLineComment, .docBlockComment,
             .carriageReturns, .carriageReturnLineFeeds, .newlines, .spaces:
            break

        case .lineComment, .blockComment:
            return true

        default:
            return false
        }
    }
    return false
}
