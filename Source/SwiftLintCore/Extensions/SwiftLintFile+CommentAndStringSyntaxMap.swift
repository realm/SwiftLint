import SourceKittenFramework
import SwiftSyntax

/// Collects only the comment and string tokens of a file, straight off the syntax tree.
///
/// SwiftSyntax classifies both context-free — comments come from trivia piece kinds, and string
/// tokens from the token kind alone, since contextual classification only ever applies to
/// identifiers. So the same ranges are reachable with a single token walk, without running the
/// general-purpose classifier over every token in the file to resolve keywords, types and
/// identifiers that the callers below discard.
/// A comment or string token, before line comments are extended over their newline.
private struct CollectedToken {
    let kind: SourceKittenFramework.SyntaxKind
    let offset: Int
    let length: Int
    let isLineComment: Bool
}

private final class CommentAndStringTokensVisitor: SyntaxVisitor {
    private(set) var tokens: [CollectedToken] = []
    private var position = 0

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        // Materializing trivia re-lexes it, so only do so for tokens that actually have some.
        if token.leadingTriviaLength.utf8Length > 0 {
            appendComments(in: token.leadingTrivia)
        }
        let textLength = token.trimmedLength.utf8Length
        // The four token kinds SwiftSyntax classifies as `stringLiteral`, plus the unknown-token
        // fallback it applies to malformed strings.
        switch token.tokenKind {
        case .stringSegment, .stringQuote, .multilineStringQuote, .singleQuote:
            tokens.append(CollectedToken(kind: .string, offset: position, length: textLength, isLineComment: false))
        case .unknown(let text) where text.hasPrefix("\""):
            tokens.append(CollectedToken(kind: .string, offset: position, length: textLength, isLineComment: false))
        default:
            break
        }
        position += textLength
        if token.trailingTriviaLength.utf8Length > 0 {
            appendComments(in: token.trailingTrivia)
        }
        return .skipChildren
    }

    private func appendComments(in trivia: Trivia) {
        for piece in trivia {
            let length = piece.sourceLength.utf8Length
            switch piece {
            case .lineComment:
                tokens.append(CollectedToken(kind: .comment, offset: position, length: length, isLineComment: true))
            case .blockComment:
                tokens.append(CollectedToken(kind: .comment, offset: position, length: length, isLineComment: false))
            case .docLineComment:
                tokens.append(CollectedToken(kind: .docComment, offset: position, length: length, isLineComment: true))
            case .docBlockComment:
                tokens.append(CollectedToken(kind: .docComment, offset: position, length: length, isLineComment: false))
            default:
                break
            }
            position += length
        }
    }
}

extension SwiftLintFile {
    /// Builds the map returned by the cached `commentAndStringSyntaxMap()`.
    ///
    /// Line comment extents match `sourceKitFreeSyntaxMap()`, which in turn matches sourcekitd:
    /// `//`-style comments cover their terminating newline, which SwiftSyntax keeps as separate
    /// trivia. Rules excluding matches that intersect comment kinds depend on those exact extents.
    func computeCommentAndStringSyntaxMap() -> SwiftLintSyntaxMap {
        let visitor = CommentAndStringTokensVisitor(viewMode: .sourceAccurate)
        visitor.walk(syntaxTree)
        let contents = stringView
        let tokens = visitor.tokens.map { token -> SyntaxToken in
            var length = token.length
            if token.isLineComment {
                let end = ByteCount(token.offset + token.length)
                let lineEnding = contents.substringWithByteRange(ByteRange(location: end, length: 2))
                switch lineEnding {
                case let ending? where ending.hasPrefix("\r\n"):
                    length += 2
                case let ending? where ending.hasPrefix("\n") || ending.hasPrefix("\r"):
                    length += 1
                case nil where contents.substringWithByteRange(
                    ByteRange(location: end, length: 1)) == "\n":
                    length += 1
                default:
                    break
                }
            }
            return SyntaxToken(type: token.kind.rawValue, offset: ByteCount(token.offset), length: ByteCount(length))
        }
        return SwiftLintSyntaxMap(value: SyntaxMap(tokens: tokens))
    }
}
