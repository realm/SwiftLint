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
    public var range: ByteRange {
        return value.range
    }

    /// The starting byte offset in a source file for this token.
    public var offset: ByteCount {
        return value.offset
    }

    /// The length in bytes for this token.
    public var length: ByteCount {
        return value.length
    }
}

public extension Array where Element == SwiftLintSyntaxToken {
    /// The kinds for these tokens.
    var kinds: [SyntaxKind] {
        return compactMap { $0.kind }
    }
}
