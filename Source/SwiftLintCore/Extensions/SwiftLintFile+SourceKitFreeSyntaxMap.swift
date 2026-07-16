import SourceKittenFramework

public extension SwiftLintFile {
    /// A syntax map equivalent to the sourcekitd-backed `syntaxMap`, built from the SwiftSyntax-derived
    /// bridge tokens so that rules using it don't require SourceKit.
    ///
    /// To preserve exact parity with SourceKit's token extents, line comment tokens (`//`-style,
    /// including doc line comments) are extended over their terminating newline: sourcekitd includes
    /// that newline in the comment token's range, while SwiftSyntax classifies it as separate trivia.
    /// Block comments end at `*/` in both. Rules that exclude matches intersecting comment kinds rely
    /// on these exact extents.
    func sourceKitFreeSyntaxMap() -> SwiftLintSyntaxMap {
        let bridgedTokens = swiftSyntaxDerivedSourceKittenTokens ?? []
        let contents = stringView
        let tokens = bridgedTokens.map { token -> SyntaxToken in
            guard let kind = token.kind, SyntaxKind.commentKinds.contains(kind),
                  contents.substringWithByteRange(ByteRange(location: token.offset, length: 2)) == "//",
                  contents.substringWithByteRange(ByteRange(location: token.range.upperBound, length: 1)) == "\n"
            else {
                return token.value
            }
            return SyntaxToken(type: token.value.type, offset: token.offset, length: token.length + 1)
        }
        return SwiftLintSyntaxMap(value: SyntaxMap(tokens: tokens))
    }
}
