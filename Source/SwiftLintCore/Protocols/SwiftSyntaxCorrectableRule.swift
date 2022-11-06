import SwiftSyntax

/// A SwiftLint CorrectableRule that performs its corrections using a SwiftSyntax `SyntaxRewriter`.
public protocol SwiftSyntaxCorrectableRule: SwiftSyntaxRule, CorrectableRule {
    /// Produce a `ViolationsSyntaxRewriter` for the given file.
    ///
    /// - parameter file: The file for which to produce the rewriter.
    ///
    /// - returns: A `ViolationsSyntaxRewriter` for the given file.
    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter?
}

public extension SwiftSyntaxCorrectableRule {
    func correct(file: SwiftLintFile) -> [Correction] {
        guard let rewriter = makeRewriter(file: file),
              case let syntaxTree = file.syntaxTree,
              case let newTree = rewriter.visit(syntaxTree),
              rewriter.correctionPositions.isNotEmpty else {
            return []
        }

        file.write(newTree.description)
        return rewriter
            .correctionPositions
            .sorted()
            .map { position in
                Correction(
                    ruleDescription: Self.description,
                    location: Location(file: file, position: position)
                )
            }
    }
}

/// A SwiftSyntax `SyntaxRewriter` that produces absolute positions where corrections were applied.
public protocol ViolationsSyntaxRewriter: SyntaxRewriter {
    /// Positions in a source file where corrections were applied.
    var correctionPositions: [AbsolutePosition] { get }
}
