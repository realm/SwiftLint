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

        guard let startIndex = firstIntersectingTokenIndex(inByteRange: byteRange) else {
            return []
        }

        func isAfterByteRange(_ token: SyntaxToken) -> Bool {
            return token.offset < byteRange.upperBound
        }

        let tokensAfterFirstIntersection = tokens
            .lazy
            .suffix(from: startIndex)
            .prefix(while: isAfterByteRange)
            .filter(intersect)

        return Array(tokensAfterFirstIntersection)
    }

    // Index of first token which intersects byterange
    // Using binary search
    func firstIntersectingTokenIndex(inByteRange byteRange: NSRange) -> Int? {
        let lastIndex = tokens.count

        // The idx, which definitely beyound byteOffset
        var bad = -1

        // The index which is definitely after byteOffset
        var good = lastIndex
        var mid = (bad + good) / 2

        // 0 0 0 0 0 1 1 1 1 1
        //           ^
        // The idea is to get _first_ token index which intesects the byteRange
        func intersectsOrAfter(at index: Int) -> Bool {
            let token = tokens[index]
            return token.offset + token.length > byteRange.location
        }

        while bad + 1 < good {
            if intersectsOrAfter(at: mid) {
                good = mid
            } else {
                bad = mid
            }
            mid = (bad + good) / 2
        }

        // Corner case, we' re out of bound, no good items in array
        if mid == lastIndex {
            return nil
        }
        return good
    }

    internal func kinds(inByteRange byteRange: NSRange) -> [SyntaxKind] {
        return tokens(inByteRange: byteRange).kinds
    }
}
