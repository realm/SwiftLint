import SwiftSyntax

/// Counts the number of lines in a scope's body.
enum BodyLineCounter {
    struct Result {
        let exceeds: Bool
        let lineCount: Int
    }

    /// This function determines if given a scope with a left/right brace, such as a function, closure, type, etc, if
    /// the "body" of that scope meets or exceeds a specified line count limit when you ignore lines only containing
    /// comments and/or whitespace.
    ///
    /// - parameter file:           The source file.
    /// - parameter leftBraceLine:  The line where the scope's left opening brace is located.
    /// - parameter rightBraceLine: The line where the scope's right closing brace is located.
    /// - parameter limit:          The body line limit to stay under, ignoring lines only containing comments and/or
    ///                             whitespace.
    ///
    /// - returns: A tuple containing whether the body `exceeds` the specific `limit` and `lineCount`, the number of
    ///            effective lines of the body ignoring lines only containing comments and/or whitespace.
    static func lineCountIgnoringCommentsAndWhitespace(
        file: SwiftLintFile, leftBraceLine: Int, rightBraceLine: Int, limit: Int
    ) -> Result {
        // Ignore left/right brace lines
        let startLine = min(leftBraceLine + 1, rightBraceLine - 1)
        let endLine = max(rightBraceLine - 1, leftBraceLine + 1)
        // Add one because if `endLine == startLine` it's still a one-line "body". Here are some examples:
        //
        //   # 1 line
        //   {}
        //
        //   # 1 line
        //   {
        //   }
        //
        //   # 1 line
        //   {
        //     print("foo")
        //   }
        //
        //   # 2 lines
        //   {
        //     let sum = 1 + 2
        //     print(sum)
        //   }
        let totalNumberOfLines = 1 + endLine - startLine
        let numberOfCommentAndWhitespaceOnlyLines = Set(startLine...endLine).subtracting(file.linesWithTokens).count
        let count = totalNumberOfLines - numberOfCommentAndWhitespaceOnlyLines
        return Result(exceeds: count >= limit, lineCount: count)
    }

    static func linesWithTokens(file: SwiftLintFile) -> Set<Int> {
        let locationConverter = file.locationConverter
        return file.syntaxTree
            .tokens(viewMode: .sourceAccurate)
            .reduce(into: []) { linesWithTokens, token in
                if let line = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line {
                    linesWithTokens.insert(line)
                }
            }
    }
}
