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
    /// - parameter value: The raw `SyntaxMap` obtained by SourceKitten.
    public init(value: SyntaxMap) {
        self.value = value
        self.tokens = value.tokens.map(SwiftLintSyntaxToken.init)
    }

    /// Returns array of syntax tokens intersecting with byte range.
    ///
    /// - parameter byteRange: Byte-based NSRange.
    ///
    /// - returns: The array of syntax tokens intersecting with byte range.
    internal func tokens(inByteRange byteRange: ByteRange) -> [SwiftLintSyntaxToken] {
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
    /// - parameter byteRange: Byte range.
    ///
    /// - returns: The syntax kinds in the specified byte range.
    internal func kinds(inByteRange byteRange: ByteRange) -> [SyntaxKind] {
        return tokens(inByteRange: byteRange).compactMap { $0.kind }
    }
}

// TODO: Move to SourceKitten

extension ByteRange {
    func contains(_ value: ByteCount) -> Bool {
        return location <= value && upperBound >= value
    }

    func intersects(_ otherRange: ByteRange) -> Bool {
        return contains(otherRange.location) ||
            contains(otherRange.location + otherRange.length) ||
            otherRange.contains(location) ||
            otherRange.contains(location + length)
    }

    func intersects(_ ranges: [ByteRange]) -> Bool {
        return ranges.contains { intersects($0) }
    }

    func union(with otherRange: ByteRange) -> ByteRange {
        let maxUpperBound = max(upperBound, otherRange.upperBound)
        let minLocation = min(location, otherRange.location)
        return ByteRange(location: minLocation, length: maxUpperBound - minLocation)
    }

    var upperBound: ByteCount {
        return location + length
    }
}
