import Foundation
import SwiftLintCore
import SwiftParser
import SwiftSyntax

/// Caches parsed file syntax tree by path.
enum FileSyntaxTreeCache {
    /// Returns the parsed source syntax tree of the file at the specified path.
    ///
    /// - parameter file: Path to file to read from disk.
    ///
    /// - returns: Parsed source file syntax tree.
    static func getSyntaxTree(forFile file: String) -> SourceFileSyntax {
        SwiftLintFile(pathDeferringReading: file).syntaxTree
    }
}
