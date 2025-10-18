import SwiftSyntax

/// Visitor to collect line numbers that are covered by multiline string literals.
///
/// This visitor traverses the syntax tree to identify multiline string literals (those using triple quotes `"""`)
/// and collects all line numbers that fall within their boundaries. This is useful for rules that need to
/// apply different behavior to content inside multiline string literals.
public final class MultilineStringLiteralVisitor: SyntaxVisitor {
    /// The location converter to use for mapping positions to line numbers.
    private let locationConverter: SourceLocationConverter

    /// Line numbers that are covered by multiline string literals.
    public private(set) var linesSpanned = Set<Int>()

    /// Initializer.
    ///
    /// - Parameter locationConverter: The location converter to use for mapping positions to line numbers.
    public init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    /// Visits string literal expressions and collects line numbers for multiline string literals.
    ///
    /// Only processes string literals that use triple quotes (`"""`) and span multiple lines.
    /// Single-line string literals are ignored.
    ///
    /// - Parameter node: The string literal expression to examine.
    override public func visitPost(_ node: StringLiteralExprSyntax) {
        guard node.openingQuote.tokenKind == .multilineStringQuote else {
            return
        }
        let startLocation = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        let endLocation = locationConverter.location(for: node.endPositionBeforeTrailingTrivia)
        guard startLocation.line < endLocation.line else {
            return
        }
        linesSpanned.formUnion(startLocation.line...endLocation.line)
    }
}
