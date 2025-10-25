import SwiftSyntax

/// Visitor to find lines that are totally empty (no code, no comments).
public final class EmptyLinesVisitor: SyntaxVisitor {
    private let locationConverter: SourceLocationConverter

    private var linesWithContent = Set<Int>()
    private var lastLine = 0

    /// Lines that are totally empty (contain neither code nor comments).
    public var emptyLines: Set<Int> {
        guard lastLine > 0 else { return [] }
        let allLines = Set(1...lastLine)
        return allLines.subtracting(linesWithContent)
    }

    /// Initializer.
    ///
    /// - Parameter locationConverter: The location converter to use for mapping positions to line numbers.
    public init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    /// Compute empty lines in the given file.
    ///
    /// - Parameter file: The SwiftLint file to analyze.
    /// - Returns: A set of line numbers that are empty.
    public static func emptyLines(in file: SwiftLintFile) -> Set<Int> {
        EmptyLinesVisitor(locationConverter: file.locationConverter)
            .walk(tree: file.syntaxTree, handler: \.emptyLines)
    }

    override public func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        processTrivia(token.leadingTrivia, endingAt: token.positionAfterSkippingLeadingTrivia)

        // Mark lines with actual code tokens (not comments).
        if token.tokenKind != .endOfFile {
            let tokenLine = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line
            linesWithContent.insert(tokenLine)
            lastLine = max(lastLine, tokenLine)
        } else {
            // For EOF token, we only update lastLine based on its position if there's actual content
            // EOF on line 1 with no preceding content means the file is empty.
            let eofLine = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line
            if eofLine > 1 || !linesWithContent.isEmpty {
                lastLine = max(lastLine, eofLine - 1) // Don't count the EOF line itself.
            }
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
                linesWithContent.formUnion(commentStartLine...commentEndLine)
                lastLine = max(lastLine, commentEndLine)
            case .newlines:
                // Track the last line even for newlines
                let newlineEndLine = locationConverter.location(for: currentPosition + piece.sourceLength).line
                lastLine = max(lastLine, newlineEndLine)
            default:
                break
            }
        }
    }
}
