/// Emits an error when a source file cannot be parsed with SwiftSyntax.
public func warnSwiftSyntaxParserFailure(for ruleName: String, in fileName: String?) {
    var message: String = "Rule \(ruleName) is disabled because the Swift Syntax tree could not be parsed."
    if let fileName = fileName {
        message += "\n SwiftSyntax could not parse file: \(fileName)"
    }
    queuedPrintError(message)
}
