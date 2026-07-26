import SwiftParser
import SwiftSyntax

/// The deepest nesting the parser descends before reporting the source as too deeply nested.
///
/// Parsing runs on a worker thread, whose stack is a fraction of the main thread's, and the parser
/// recurses once per level of nesting. SwiftSyntax's own ceiling of 256 is meant to stop the parser
/// exhausting the stack, but it is calibrated for a large one: on a worker the stack runs out at
/// around a hundred levels, before the ceiling can stop anything, and the process dies.
private let maximumParserNestingLevel = 48

extension SwiftLintFile {
    /// Parses source, bounding how deeply the parser may nest.
    ///
    /// - parameter contents: The source to parse.
    ///
    /// - returns: The parsed tree.
    static func parsedSyntaxTree(of contents: String) -> SourceFileSyntax {
        // Only the buffer-taking entry point accepts a nesting bound.
        var source = contents
        return source.withUTF8 { buffer in
            Parser.parse(source: buffer, maximumNestingLevel: maximumParserNestingLevel)
        }
    }
}
