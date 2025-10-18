import SwiftSyntax

/// A visitor to collect line numbers that are covered by multiline string literals.
public final class MultilineStringLiteralVisitor: SyntaxVisitor {
    public let locationConverter: SourceLocationConverter
    public private(set) var linesSpanned = Set<Int>()

    public init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    public override func visitPost(_ node: StringLiteralExprSyntax) {
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
