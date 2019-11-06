import Foundation
import SourceKittenFramework

extension SyntaxMap {
    /// Returns array of SyntaxTokens intersecting with byte range
    ///
    /// - Parameter byteRange: byte based NSRange
    internal func tokens(inByteRange byteRange: NSRange) -> [SyntaxToken] {
        func intersect(_ token: SyntaxToken) -> Bool {
            return NSRange(location: token.offset, length: token.length)
                .intersects(byteRange)
        }

        func intersectsOrAfter(_ token: SyntaxToken) -> Bool {
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

    internal func kinds(inByteRange byteRange: NSRange) -> [SyntaxKind] {
        return tokens(inByteRange: byteRange).kinds
    }
}
