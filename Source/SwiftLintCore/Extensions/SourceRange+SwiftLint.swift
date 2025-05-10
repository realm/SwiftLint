import SwiftSyntax

public extension SourceRange {
    /// Check if a position is contained within this range.
    ///
    /// - parameter position:          The position to check.
    /// - parameter locationConverter: The location converter to use to perform the check.
    ///
    /// - returns: Whether the specified position is contained within this range.
    func contains(_ position: AbsolutePosition, locationConverter: SourceLocationConverter) -> Bool {
        let startPosition = locationConverter.position(ofLine: start.line, column: start.column)
        let endPosition = locationConverter.position(ofLine: end.line, column: end.column)
        return startPosition <= position && position <= endPosition
    }
}
