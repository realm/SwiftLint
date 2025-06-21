import Foundation
import SourceKittenFramework

public extension StringView {
    /// Converts a line and column position in a code snippet to a byte offset.
    /// - Parameters:
    ///   - line: Line in code snippet
    ///   - bytePosition: Byte position in line
    /// - Returns: Byte offset coinciding with the line and the column given
    func byteOffset(forLine line: Int64, bytePosition: Int64) -> ByteCount? {
        guard line > 0, line <= lines.count, bytePosition > 0 else {
            return nil
        }
        return lines[Int(line) - 1].byteRange.location + ByteCount(bytePosition - 1)
    }

    /// Matches a pattern in the string view and returns ranges for the specified capture group.
    /// This method does not use SourceKit and is suitable for SwiftSyntax mode.
    /// - Parameters:
    ///   - pattern: The regular expression pattern to match.
    ///   - captureGroup: The capture group index to extract (0 for the full match).
    /// - Returns: An array of NSRange objects for the matched capture groups.
    func match(pattern: String, captureGroup: Int = 0) -> [NSRange] {
        regex(pattern).matches(in: self).compactMap { match in
            let range = match.range(at: captureGroup)
            return range.location != NSNotFound ? range : nil
        }
    }
}
