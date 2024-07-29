import Foundation
import SwiftSyntax

/// A SwiftLint CorrectableRule that performs its corrections using a SwiftSyntax `SyntaxRewriter`.
public protocol SwiftSyntaxCorrectableRule: SwiftSyntaxRule, CorrectableRule {
    /// Produce a `ViolationsSyntaxRewriter` for the given file.
    ///
    /// - parameter file: The file for which to produce the rewriter.
    ///
    /// - returns: A `ViolationsSyntaxRewriter` for the given file. May be `nil` in which case the rule visitor's
    ///            collected `violationCorrections` will be used.
    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter<ConfigurationType>?
}

public extension SwiftSyntaxCorrectableRule {
    func makeRewriter(file _: SwiftLintFile) -> ViolationsSyntaxRewriter<ConfigurationType>? {
        nil
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        guard let syntaxTree = preprocess(file: file) else {
            return []
        }
        if let rewriter = makeRewriter(file: file) {
            let newTree = rewriter.visit(syntaxTree)
            let positions = rewriter.correctionPositions
            guard positions.isNotEmpty else {
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
        let violations = makeVisitor(file: file)
            .walk(tree: syntaxTree, handler: \.violations)
        guard violations.isNotEmpty else {
            return []
        }

        let locationConverter = file.locationConverter
        let disabledRegions = file.regions()
            .filter { $0.areRulesDisabled(ruleIDs: Self.description.allIdentifiers) }
            .compactMap { $0.toSourceRange(locationConverter: locationConverter) }

        typealias CorrectionRange = (range: NSRange, correction: String)
        let correctionRanges = violations
            .filter { !$0.position.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) }
            .compactMap(\.correction)
            .compactMap { correction in
                file.stringView.NSRange(start: correction.start, end: correction.end).map { range in
                    CorrectionRange(range: range, correction: correction.replacement)
                }
            }
            .sorted { (lhs: CorrectionRange, rhs: CorrectionRange) -> Bool in
                lhs.range.location > rhs.range.location
            }
        guard correctionRanges.isNotEmpty else {
            return []
        }

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
open class ViolationsSyntaxRewriter<Configuration: RuleConfiguration>: SyntaxRewriter {
    /// A rule's configuration.
    public let configuration: Configuration
    /// The file from which the traversed syntax tree stems from.
    public let file: SwiftLintFile

    /// A converter of positions in the traversed source file.
    public lazy var locationConverter = file.locationConverter
    /// The regions in the traversed file that are disabled by a command.
    public lazy var disabledRegions = {
        file.regions()
            .filter { $0.areRulesDisabled(ruleIDs: Configuration.Parent.description.allIdentifiers) }
            .compactMap { $0.toSourceRange(locationConverter: locationConverter) }
    }()

    /// Positions in a source file where corrections were applied.
    public var correctionPositions = [AbsolutePosition]()

    /// Initializer for a ``ViolationsSyntaxRewriter``.
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: File from which the syntax tree stems from.
    @inlinable
    public init(configuration: Configuration, file: SwiftLintFile) {
        self.configuration = configuration
        self.file = file
    }

    override open func visitAny(_ node: Syntax) -> Syntax? {
        node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) ? node : nil
    }
}
