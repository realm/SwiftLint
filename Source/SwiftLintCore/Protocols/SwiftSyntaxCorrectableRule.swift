import SwiftSyntax

/// A SwiftLint CorrectableRule that performs its corrections using a SwiftSyntax `SyntaxRewriter`.
public protocol SwiftSyntaxCorrectableRule: SwiftSyntaxRule, CorrectableRule {
    /// Produce a `ViolationsSyntaxRewriter` for the given file.
    ///
    /// - parameter file: The file for which to produce the rewriter.
    ///
    /// - returns: A `ViolationsSyntaxRewriter` for the given file. May be `nil` in which case the rule visitor's
    ///            collected `violationCorrections` will be used.
    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter?
}

public extension SwiftSyntaxCorrectableRule {
    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        nil
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        if let rewriter = makeRewriter(file: file) {
            let syntaxTree = file.syntaxTree
            let newTree = rewriter.visit(syntaxTree)
            let positions = rewriter.correctionPositions
            if positions.isEmpty {
                return []
            }
            let corrections = positions
                .sorted()
                .map { position in
                    Correction(
                        ruleDescription: Self.description,
                        location: Location(file: file, position: position)
                    )
                }
            file.write(newTree.description)
            return corrections
        }

        // There is no rewriter. Falling back to the correction ranges collected by the visitor (if any).
        let violationCorrections = makeVisitor(file: file).walk(file: file, handler: \.violationCorrections)
        if violationCorrections.isEmpty {
            return []
        }
        let correctionRanges = violationCorrections
            .compactMap { correction in
                file.stringView.NSRange(start: correction.start, end: correction.end).map { range in
                    (range: range, correction: correction.replacement)
                }
            }
            .filter { file.ruleEnabled(violatingRange: $0.range, for: self) != nil }
            .reversed()
        var corrections = [Correction]()
        var contents = file.contents
        for range in correctionRanges {
            let contentsNSString = contents.bridge()
            contents = contentsNSString.replacingCharacters(in: range.range, with: range.correction)
            let location = Location(file: file, characterOffset: range.range.location)
            corrections.append(Correction(ruleDescription: Self.description, location: location))
        }
        file.write(contents)
        return corrections
    }
}

/// A SwiftSyntax `SyntaxRewriter` that produces absolute positions where corrections were applied.
public protocol ViolationsSyntaxRewriter: SyntaxRewriter {
    /// Positions in a source file where corrections were applied.
    var correctionPositions: [AbsolutePosition] { get }
}
