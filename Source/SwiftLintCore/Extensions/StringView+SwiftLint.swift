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
}
