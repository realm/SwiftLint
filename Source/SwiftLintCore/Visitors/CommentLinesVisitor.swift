import SwiftSyntax

/// Visitor to find lines that contain only comments.
public final class CommentLinesVisitor: SyntaxVisitor {
    private let locationConverter: SourceLocationConverter

    private var linesWithComments = Set<Int>()
    private var linesWithCode = Set<Int>()

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

    override public func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        processTrivia(token.leadingTrivia, endingAt: token.positionAfterSkippingLeadingTrivia)

        // Mark lines with actual code tokens (not comments).
        if token.tokenKind != .endOfFile {
            let tokenLine = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line
            linesWithCode.insert(tokenLine)
        }

        processTrivia(token.trailingTrivia, endingAt: token.endPosition)
        return .visitChildren
    }

    private func processTrivia(_ trivia: Trivia, endingAt endPosition: AbsolutePosition) {
        var currentPosition = endPosition

        for piece in trivia.reversed() {
            currentPosition -= piece.sourceLength

            switch piece {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                // Collect all lines that this comment spans.
                let commentStartLine = locationConverter.location(for: currentPosition).line
                let commentEndLine = locationConverter.location(for: currentPosition + piece.sourceLength).line
                linesWithComments.formUnion(commentStartLine...commentEndLine)
            default:
                break
            }
        }
    }
}
