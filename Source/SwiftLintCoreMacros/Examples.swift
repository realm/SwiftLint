import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Expands `#examples(["a", "b"])` into `[Example(code: "a", file:, line:), Example(code: "b", file:, line:)]`,
/// capturing the file and line of each element so test failures and documentation point at the right location.
/// Elements are usually string literals, but an existing `Example` expression works too.
enum Examples: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let array = node.arguments.first?.expression.as(ArrayExprSyntax.self) else {
            context.diagnose(SwiftLintCoreMacroError.examplesNotArrayLiteral.diagnose(at: node))
            return "[]"
        }
        // Rewrite the original array in place (rather than building a fresh one) so the expansion keeps the
        // source's brackets and per-element newlines, making it readable when a developer expands the macro.
        let newElements = array.elements.map { element in
            element.with(
                \.expression,
                makeExample(from: element.expression, in: context, preservingTriviaOf: element.expression)
            )
        }
        return ExprSyntax(array.with(\.elements, ArrayElementListSyntax(newElements)))
    }
}

/// Expands `#corrections(["a": "b"])` into `[Example(code: "a", …): Example(code: "b", …)]`, capturing the file
/// and line of each key and value. Keys and values are usually string literals, but an existing `Example`
/// expression works too. Intended for a rule's `corrections` dictionary.
enum Corrections: ExpressionMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let dictionary = node.arguments.first?.expression.as(DictionaryExprSyntax.self) else {
            context.diagnose(SwiftLintCoreMacroError.correctionsNotDictionaryLiteral.diagnose(at: node))
            return "[:]"
        }
        guard case let .elements(elements) = dictionary.content else {
            return "[:]"
        }
        let newElements = elements.map { element in
            element
                .with(\.key, makeExample(from: element.key, in: context, preservingTriviaOf: element.key))
                .with(\.value, makeExample(from: element.value, in: context, preservingTriviaOf: element.value))
        }
        return ExprSyntax(dictionary.with(\.content, .elements(DictionaryElementListSyntax(newElements))))
    }
}

/// Wraps an expression in an `Example(…, file:, line:)` call, baking in the expression's own source location.
///
/// A string literal becomes `Example(code: "…", …)`; any other expression is assumed to already be an `Example`
/// (e.g. `"code".asExample(configuration:)`) and is passed through the `Example(_:file:line:)` initializer to
/// re-capture its location. The `Example` type is `ExpressibleByStringInterpolation` only so the macro can be
/// typed `[Example]`; that conversion traps at runtime, so a literal must go through the labelled `code:`
/// initializer.
///
/// The surrounding trivia is replaced with the trivia of `triviaSource` (the original node being substituted), so
/// the result slots into the same position as the expression it replaces.
private func makeExample(
    from expression: ExprSyntax,
    in context: some MacroExpansionContext,
    preservingTriviaOf triviaSource: ExprSyntax? = nil
) -> ExprSyntax {
    let code = expression.trimmed
    let fileID = context.location(of: expression, at: .afterLeadingTrivia, filePathMode: .fileID)
    let filePath = context.location(of: expression, at: .afterLeadingTrivia, filePathMode: .filePath)
    guard let fileID, let filePath else {
        context.diagnose(SwiftLintCoreMacroError.missingSourceLocation.diagnose(at: expression))
        return expression
    }

    let isStringLiteral = expression.is(StringLiteralExprSyntax.self)
    let example: ExprSyntax = isStringLiteral
        ? "Example(code: \(code), fileID: \(fileID.file), file: \(filePath.file), line: \(filePath.line))"
        : "Example(\(code), fileID: \(fileID.file), file: \(filePath.file), line: \(filePath.line))"
    guard let triviaSource else {
        return example
    }
    return example
        .with(\.leadingTrivia, triviaSource.leadingTrivia)
        .with(\.trailingTrivia, triviaSource.trailingTrivia)
}
