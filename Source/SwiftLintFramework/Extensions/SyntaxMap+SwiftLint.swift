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

        guard let startIndex = tokens.firstIndex(where: intersect) else {
            return []
        }
        let tokensBeginningIntersect = tokens.lazy.suffix(from: startIndex)
        return Array(tokensBeginningIntersect.filter(intersect))
    }

    internal func kinds(inByteRange byteRange: NSRange) -> [SyntaxKind] {
        return tokens(inByteRange: byteRange).kinds
    }
}
