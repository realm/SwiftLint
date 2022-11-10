/// An unused Swift source code declaration.
public struct UnusedDeclaration {
    /// The description to print when logging this unused declaration.
    public let logDescription: String

    /// Creates an `UnusedDeclaration` from the specified `Declaration` and a path prefix to use to truncate
    /// the declaration's original file path.
    ///
    /// - parameter declaration: The unused declaration.
    init(_ declaration: Declaration) {
        logDescription =
            """
            \(declaration.file):\(declaration.line):\(declaration.column): \
            error: Unused declaration named '\(declaration.name)'
            """
    }
}
