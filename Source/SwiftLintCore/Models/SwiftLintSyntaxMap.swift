import SourceKittenFramework

/// Represents a Swift file's syntax information.
public struct SwiftLintSyntaxMap {
    /// The SwiftLint-specific syntax tokens for this syntax map.
    public let tokens: [SwiftLintSyntaxToken]

    /// Creates a `SwiftLintSyntaxMap` from the raw `SyntaxMap` obtained by SourceKitten.
    ///
    /// - parameter value: The raw `SyntaxMap` obtained by SourceKitten.
    public init(value: SyntaxMap) {
        self.tokens = value.tokens.map(SwiftLintSyntaxToken.init)
    }

    /// Creates a `SwiftLintSyntaxMap` from tokens already in SwiftLint's representation, such as
    /// tokens derived from SwiftSyntax classifications. Tokens must be sorted by position.
    ///
    /// - parameter tokens: The syntax tokens for this syntax map.
    package init(tokens: [SwiftLintSyntaxToken]) {
        self.tokens = tokens
    }

    /// Returns array of syntax tokens intersecting with byte range.
    ///
    /// - parameter byteRange: Byte-based NSRange.
    ///
    /// - returns: The array of syntax tokens intersecting with byte range.
    public func tokens(inByteRange byteRange: ByteRange) -> [SwiftLintSyntaxToken] {
        func intersect(_ token: SwiftLintSyntaxToken) -> Bool {
            token.range.intersects(byteRange)
        }

        func intersectsOrAfter(_ token: SwiftLintSyntaxToken) -> Bool {
            token.offset + token.length > byteRange.location
        }

        guard let startIndex = tokens.firstIndexAssumingSorted(where: intersectsOrAfter) else {
            return []
        }

        let tokensAfterFirstIntersection = tokens
            .lazy
            .suffix(from: startIndex)
            .prefix(while: { $0.offset < byteRange.upperBound })
            .filter(intersect)

        return Array(tokensAfterFirstIntersection)
    }

    /// Returns the syntax kinds in the specified byte range.
    ///
    /// - parameter byteRange: Byte range.
    ///
    /// - returns: The syntax kinds in the specified byte range.
    public func kinds(inByteRange byteRange: ByteRange) -> [SyntaxKind] {
        tokens(inByteRange: byteRange).compactMap(\.kind)
    }
}
