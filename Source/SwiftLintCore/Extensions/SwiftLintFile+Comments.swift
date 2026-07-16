import SourceKittenFramework
import SwiftSyntax

public extension SwiftLintFile {
    /// The byte ranges of all comment trivia pieces (line, doc-line, block, and doc-block) in the
    /// file, in source order.
    ///
    /// Comments are read directly off each token of the (cached) syntax tree rather than via
    /// `syntaxClassifications`, which would additionally run SwiftSyntax's general-purpose
    /// classifier over every non-comment token in the file.
    func commentByteRanges() -> [ByteRange] {
        var ranges = [ByteRange]()
        for token in syntaxTree.tokens(viewMode: .sourceAccurate) {
            var position = token.position
            for piece in token.leadingTrivia {
                if piece.isComment {
                    ranges.append((position..<(position + piece.sourceLength)).toSourceKittenByteRange())
                }
                position += piece.sourceLength
            }
            position = token.endPositionBeforeTrailingTrivia
            for piece in token.trailingTrivia {
                if piece.isComment {
                    ranges.append((position..<(position + piece.sourceLength)).toSourceKittenByteRange())
                }
                position += piece.sourceLength
            }
        }
        return ranges
    }
}
