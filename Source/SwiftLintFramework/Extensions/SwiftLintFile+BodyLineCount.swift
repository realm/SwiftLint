import SwiftSyntax

extension SwiftLintFile {
    /// This function determines if given a scope with a left/right brace, such as a function, closure, type, etc, how
    /// many lines the "body" spans when you ignore lines only containing comments and/or whitespace.
    ///
    /// - parameter leftBraceLine:  The line where the scope's left opening brace is located.
    /// - parameter rightBraceLine: The line where the scope's right closing brace is located.
    ///
    /// - returns: The number of effective lines of the body ignoring lines only containing comments and/or whitespace.
    func bodyLineCountIgnoringCommentsAndWhitespace(
        leftBraceLine: Int, rightBraceLine: Int
    ) -> Int {
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
        let numberOfCommentAndWhitespaceOnlyLines = Set(startLine...endLine).subtracting(linesWithTokens).count
        return totalNumberOfLines - numberOfCommentAndWhitespaceOnlyLines
    }

    func computeLinesWithTokens() -> Set<Int> {
        let locationConverter = locationConverter
        return syntaxTree
            .tokens(viewMode: .sourceAccurate)
            .reduce(into: []) { linesWithTokens, token in
                if case .stringSegment = token.tokenKind {
                    let sourceRange = token
                        .trimmed
                        .sourceRange(converter: locationConverter)
                    let startLine = sourceRange.start.line!
                    let endLine = sourceRange.end.line!
                    linesWithTokens.formUnion(startLine...endLine)
                } else if let line = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line {
                    linesWithTokens.insert(line)
                }
            }
    }
}
