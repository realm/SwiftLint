import SwiftSyntax

public extension SourceRange {
    /// Check if a position is contained within this range.
    ///
    /// - parameter position:          The position to check.
    /// - parameter locationConverter: The location converter to use to perform the check.
    ///
    /// - returns: Whether the specified position is contained within this range.
    func contains(_ position: AbsolutePosition, locationConverter: SourceLocationConverter) -> Bool {
        let startPosition = locationConverter.position(ofLine: start.line ?? 1, column: start.column ?? 1)
        let endPosition = locationConverter.position(ofLine: end.line ?? 1, column: end.column ?? 1)
        return startPosition <= position && position <= endPosition
    }
}
