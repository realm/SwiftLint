import Foundation
import SourceKittenFramework

/// Represents a Swift file's syntax information.
public struct SwiftLintSyntaxMap {
    /// The raw `SyntaxMap` obtained by SourceKitten.
    public let value: SyntaxMap

    /// The SwiftLint-specific syntax tokens for this syntax map.
    public let tokens: [SwiftLintSyntaxToken]

    /// Creates a `SwiftLintSyntaxMap` from the raw `SyntaxMap` obtained by SourceKitten.
    ///
    /// - arameter value: The raw `SyntaxMap` obtained by SourceKitten.
    public init(value: SyntaxMap) {
        self.value = value
        self.tokens = value.tokens.map(SwiftLintSyntaxToken.init)
    }

    /// Returns array of SyntaxTokens intersecting with byte range.
    ///
    /// - parameter byteRange: Byte-based NSRange.
    internal func tokens(inByteRange byteRange: NSRange) -> [SwiftLintSyntaxToken] {
        func intersect(_ token: SwiftLintSyntaxToken) -> Bool {
            return token.range.intersects(byteRange)
        }

        func intersectsOrAfter(_ token: SwiftLintSyntaxToken) -> Bool {
            return token.offset + token.length > byteRange.location
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
    /// - parameter byteRange: Byte-based NSRange.
    internal func kinds(inByteRange byteRange: NSRange) -> [SyntaxKind] {
        return tokens(inByteRange: byteRange).compactMap { $0.kind }
    }
}
