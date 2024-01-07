import SwiftSyntax

/// Rewriter that indents or unindents a syntax piece including comments and nested
/// AST nodes (e.g. a code block in a code block).
public class CodeIndentingRewriter: SyntaxRewriter {
    /// Style defining whether the rewriter shall indent or unindent and whether it shall use tabs or spaces and
    /// how many of them.
    public enum IndentationStyle {
        /// Indentation with a number of spaces.
        case indentSpaces(Int)
        /// Reverse indentation of a number of spaces.
        case unindentSpaces(Int)
        /// Indentation with a number of tabs
        case indentTabs(Int)
        /// Reverse indentation of a number of tabs.
        case unindentTabs(Int)
    }

    private let style: IndentationStyle
    private var isFirstToken = true

    /// Initializer accepting an indentation style.
    ///
    /// - parameter style: Indentation style. The default is indentation by 4 spaces.
    public init(style: IndentationStyle = .indentSpaces(4)) {
        self.style = style
    }

    override public func visit(_ token: TokenSyntax) -> TokenSyntax {
        defer { isFirstToken = false }
        return super.visit(
            token.with(\.leadingTrivia, Trivia(pieces: indentedTriviaPieces(for: token.leadingTrivia)))
        )
    }

    private func indentedTriviaPieces(for trivia: Trivia) -> [TriviaPiece] {
        switch style {
        case let .indentSpaces(number): indent(trivia: trivia, by: .spaces(number))
        case let .indentTabs(number): indent(trivia: trivia, by: .tabs(number))
        case let .unindentSpaces(number): unindent(trivia: trivia, by: .spaces(number))
        case let .unindentTabs(number): unindent(trivia: trivia, by: .tabs(number))
        }
    }

    private func indent(trivia: Trivia, by indentation: TriviaPiece) -> [TriviaPiece] {
        let indentedPieces = trivia.pieces.flatMap { piece in
            switch piece {
            case .newlines: [piece, indentation]
            default: [piece]
            }
        }
        return isFirstToken ? [indentation] + indentedPieces : indentedPieces
    }

    private func unindent(trivia: Trivia, by indentation: TriviaPiece) -> [TriviaPiece] {
        var indentedTrivia = [TriviaPiece]()
        for piece in trivia.pieces {
            if !isFirstToken {
                guard case .newlines = indentedTrivia.last else {
                    indentedTrivia.append(piece)
                    continue
                }
            }
            switch (piece, indentation) {
            case let (.spaces(number), .spaces(requestedNumber)) where number >= requestedNumber:
                indentedTrivia.append(.spaces(number - requestedNumber))
                if isFirstToken { break }
            case let (.tabs(number), .tabs(requestedNumber)) where number >= requestedNumber:
                indentedTrivia.append(.tabs(number - requestedNumber))
                if isFirstToken { break }
            default: indentedTrivia.append(piece)
            }
        }
        return indentedTrivia
    }
}
