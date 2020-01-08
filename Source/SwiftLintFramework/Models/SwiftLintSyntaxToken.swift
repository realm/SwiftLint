import Foundation
import SourceKittenFramework

/// A SwiftLint-aware Swift syntax token.
public struct SwiftLintSyntaxToken {
    /// The raw `SyntaxToken` obtained by SourceKitten.
    public let value: SyntaxToken

    /// The syntax kind associated with is token.
    public let kind: SyntaxKind?

    /// Creates a `SwiftLintSyntaxToken` from the raw `SyntaxToken` obtained by SourceKitten.
    ///
    /// - parameter value: The raw `SyntaxToken` obtained by SourceKitten.
    public init(value: SyntaxToken) {
        self.value = value
        kind = SyntaxKind(rawValue: value.type)
    }

    /// The byte range in a source file for this token.
    public var range: NSRange {
        return NSRange(location: value.offset, length: value.length)
    }

    /// The starting byte offset in a source file for this token.
    public var offset: Int {
        return value.offset
    }

    /// The length in bytes for this token.
    public var length: Int {
        return value.length
    }
}

extension Array where Element == SwiftLintSyntaxToken {
    var kinds: [SyntaxKind] {
        return compactMap { $0.kind }
    }
}
