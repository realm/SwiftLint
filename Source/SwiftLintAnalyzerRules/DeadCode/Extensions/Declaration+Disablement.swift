import SwiftLintCore
import SwiftSyntax

extension Declaration {
    /// Returns if the current declaration should not be reported as unused because it is disabled
    /// by a SwiftLint-style comment command.
    ///
    /// - parameter tree: The source file syntax tree obtained by SwiftSyntax.
    ///
    /// - returns: True if the declaration is disabled.
    func isDisabled(in tree: SourceFileSyntax) -> Bool {
        let location = Location(file: file, line: line, character: column)
        let file = SwiftLintFile(pathDeferringReading: file)
        let regionContainingLine = file.regions().first { $0.contains(location) }
        return regionContainingLine?.isRuleIdentifierDisabled("unused_declaration") ?? false
    }
}
