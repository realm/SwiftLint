import SourceKittenFramework

/// A rule that leverages the Swift source's pre-typechecked Abstract Syntax Tree to recurse into the source's
/// structure, validating the rule recursively in nested source bodies.
public protocol ASTRule: Rule {
    /// The kind of token being recursed over.
    associatedtype KindType: RawRepresentable

    /// Executes the rule on a file and a subset of its AST structure, returning any violations to the rule's
    /// expectations.
    ///
    /// - parameter file:       The file for which to execute the rule.
    /// - parameter kind:       The kind of token being recursed over.
    /// - parameter dictionary: The dictionary for an AST subset to validate.
    ///
    /// - returns: All style violations to the rule's expectations.
    func validate(file: SwiftLintFile, kind: KindType, dictionary: SourceKittenDictionary) -> [StyleViolation]

    /// Get the `kind` from the specified dictionary.
    ///
    /// - parameter dictionary: The `SourceKittenDictionary` representing the source structure from which to extract the
    ///                         `kind`.
    ///
    /// - returns: The `kind` from the specified dictionary, if one was found.
    func kind(from dictionary: SourceKittenDictionary) -> KindType?
}

public extension ASTRule {
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validate(file: file, dictionary: file.structureDictionary)
    }

    /// Executes the rule on a file and a subset of its AST structure, returning any violations to the rule's
    /// expectations.
    ///
    /// - parameter file:       The file for which to execute the rule.
    /// - parameter dictionary: The dictionary for an AST subset to validate.
    ///
    /// - returns: All style violations to the rule's expectations.
    func validate(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return dictionary.traverseDepthFirst { subDict in
            guard let kind = self.kind(from: subDict) else { return nil }
            return validate(file: file, kind: kind, dictionary: subDict)
        }
    }
}

public extension ASTRule where KindType == SwiftDeclarationKind {
    func kind(from dictionary: SourceKittenDictionary) -> KindType? {
        return dictionary.declarationKind
    }
}

public extension ASTRule where KindType == SwiftExpressionKind {
    func kind(from dictionary: SourceKittenDictionary) -> KindType? {
        return dictionary.expressionKind
    }
}

public extension ASTRule where KindType == StatementKind {
    func kind(from dictionary: SourceKittenDictionary) -> KindType? {
        return dictionary.statementKind
    }
}
