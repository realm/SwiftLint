import Foundation
import SourceKittenFramework
import SwiftSyntax

public extension StringView {
    /// Converts two absolute positions from SwiftSyntax to a valid `NSRange` if possible.
    ///
    /// - parameter start: Starting position.
    /// - parameter end:   End position.
    ///
    /// - returns: `NSRange` or nil in case of empty string.
    func NSRange(start: AbsolutePosition, end: AbsolutePosition) -> NSRange? {
        precondition(end >= start, "End position should be bigger than the start position")
        return NSRange(start: start, length: ByteCount(end.utf8Offset - start.utf8Offset))
    }

    /// Converts absolute position with length from SwiftSyntax to a valid `NSRange` if possible.
    ///
    /// - parameter start:  Starting position.
    /// - parameter length: Length in bytes.
    ///
    /// - returns: `NSRange` or nil in case of empty string.
    private func NSRange(start: AbsolutePosition, length: ByteCount) -> NSRange? {
        let byteRange = ByteRange(location: ByteCount(start), length: length)
        return byteRangeToNSRange(byteRange)
    }
}
