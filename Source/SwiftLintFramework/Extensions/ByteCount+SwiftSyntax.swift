import SourceKittenFramework
import SwiftSyntax

public extension ByteCount {
    /// Converts a SwiftSyntax `AbsolutePosition` to a SourceKitten `ByteCount`.
    ///
    /// - parameter position: The SwiftSyntax position to convert.
    init(_ position: AbsolutePosition) {
        self.init(position.utf8Offset)
    }
}
