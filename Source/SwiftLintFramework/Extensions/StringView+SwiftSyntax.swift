import Foundation
import SourceKittenFramework
import SwiftSyntax

extension StringView {
    /// Converts two absolute positions from SwiftSyntax to a valid `NSRange` if possible.
    ///
    /// - parameter start: Starting position.
    /// - parameter end:   End position.
    ///
    /// - returns: `NSRange` or nil in case of empty string.
    func NSRange(start: AbsolutePosition, end: AbsolutePosition) -> NSRange? {
        precondition(end.utf8Offset >= start.utf8Offset, "End position should be bigger than start position")
        return NSRange(start: start, length: end.utf8Offset - start.utf8Offset)
    }

    /// Converts absolute position with length from SwiftSyntax to a valid `NSRange` if possible.
    ///
    /// - parameter start:  Starting position.
    /// - parameter length: Length in bytes.
    ///
    /// - returns: `NSRange` or nil in case of empty string.
    private func NSRange(start: AbsolutePosition, length: Int) -> NSRange? {
        let byteRange = ByteRange(location: ByteCount(start.utf8Offset), length: ByteCount(length))
        return byteRangeToNSRange(byteRange)
    }
}
