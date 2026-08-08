import SwiftSyntax

/// Visitor to find lines that contain only comments.
public final class CommentLinesVisitor: SyntaxVisitor {
    private let locationConverter: SourceLocationConverter

    private var linesWithComments = Set<Int>()

    // Cached line for the most recently looked up token so that consecutive tokens on the
    // same line don't need another (comparatively expensive) location converter lookup.
    private var cachedLine = 0
    private var cachedLineStart = AbsolutePosition(utf8Offset: 0)
    private var cachedLineEnd = AbsolutePosition(utf8Offset: 0)

    // The line most recently inserted into `linesWithCode`, to skip redundant set inserts
    // for consecutive tokens on the same line.
    private var lastLineWithCode = 0

    /// Lines that contain actual code (not comments).
    public private(set) var linesWithCode = Set<Int>()

    /// Lines that contain only comments (and whitespace).
    public var commentOnlyLines: Set<Int> {
        linesWithComments.subtracting(linesWithCode)
    }

    /// Initializer.
    ///
    /// - Parameter locationConverter: The location converter to use for mapping positions to line numbers.
    public init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    /// Compute all comment-only lines in the given file.
    ///
    /// - Parameter file: The SwiftLint file to analyze.
    /// - Returns: A set of line numbers that contain only comments.
    public static func commentLines(in file: SwiftLintFile) -> Set<Int> {
        CommentLinesVisitor(locationConverter: file.locationConverter)
            .walk(tree: file.syntaxTree, handler: \.commentOnlyLines)
    }

    override public func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        let position = token.position
        let leadingTriviaLength = token.leadingTriviaLength

        // Materializing trivia is expensive for parsed tokens, so only do it when there is any.
        if leadingTriviaLength.utf8Length > 0 {
            processTrivia(token.leadingTrivia, startingAt: position)
        }

        let tokenStart = position + leadingTriviaLength
        let trailingTriviaLength = token.trailingTriviaLength
        let textEnd = token.endPosition - trailingTriviaLength

        // Mark lines with actual code tokens (not comments). Only zero-length tokens can be
        // `endOfFile`, so the (expensive) token kind is only computed for those.
        if textEnd > tokenStart || token.tokenKind != .endOfFile {
            let tokenLine = line(for: tokenStart)
            if tokenLine != lastLineWithCode {
                linesWithCode.insert(tokenLine)
                lastLineWithCode = tokenLine
            }
        }

        if trailingTriviaLength.utf8Length > 0 {
            processTrivia(token.trailingTrivia, startingAt: textEnd)
        }
        return .visitChildren
    }

    private func processTrivia(_ trivia: Trivia, startingAt startPosition: AbsolutePosition) {
        var currentPosition = startPosition

        for piece in trivia {
            let pieceLength = piece.sourceLength

            switch piece {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                // Collect all lines that this comment spans.
                let commentStartLine = locationConverter.location(for: currentPosition).line
                let commentEndLine = locationConverter.location(for: currentPosition + pieceLength).line
                linesWithComments.formUnion(commentStartLine...commentEndLine)
            default:
                break
            }

            currentPosition += pieceLength
        }
    }

    private func line(for tokenStart: AbsolutePosition) -> Int {
        if tokenStart >= cachedLineStart, tokenStart < cachedLineEnd {
            return cachedLine
        }
        let location = locationConverter.location(for: tokenStart)
        cachedLine = location.line
        // The column is the 1-based UTF-8 offset of the position from the start of its line.
        cachedLineStart = AbsolutePosition(utf8Offset: tokenStart.utf8Offset - (location.column - 1))
        // Clamps to the end of the file for the last line, which is exactly this line's end.
        cachedLineEnd = locationConverter.position(ofLine: cachedLine + 1, column: 1)
        return cachedLine
    }
}
