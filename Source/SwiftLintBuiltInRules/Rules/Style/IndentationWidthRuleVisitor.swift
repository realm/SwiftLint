import SourceKittenFramework
import SwiftLintCore
import SwiftSyntax

// Helper visitor for `IndentationWidthRule`.

/// The extent of a multiline string literal, matching the extent of the literal's string token in SourceKit's syntax
/// map: it covers everything from the first opening delimiter to the end of the closing delimiter.
struct MultilineStringSpan {
    let range: ByteRange
    /// The byte offsets of the backslashes introducing the literal's interpolation segments.
    let interpolationStarts: [ByteCount]
}

/// Collects everything `IndentationWidthRule` needs from the syntax tree in a single walk: the continuation
/// lines of multi-line conditions and the spans of multiline string literals.
final class IndentationWidthRuleVisitor: SyntaxVisitor {
    private let locationConverter: SourceLocationConverter
    /// Maps line index → expected indentation column for continuation lines of multi-line conditions.
    /// When `include_multiline_conditions` is false, these lines are skipped entirely (the expected
    /// column is still stored so the line is recognized as a continuation).
    private(set) var continuationLines = [Int: Int]()
    /// The spans of all multiline string literals in the file, as yielded by `visitPost`.
    private(set) var spans = [MultilineStringSpan]()

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: GuardStmtSyntax) {
        collectContinuationLines(keyword: node.guardKeyword, conditions: node.conditions)
    }

    override func visitPost(_ node: IfExprSyntax) {
        collectContinuationLines(keyword: node.ifKeyword, conditions: node.conditions)
    }

    override func visitPost(_ node: WhileStmtSyntax) {
        collectContinuationLines(keyword: node.whileKeyword, conditions: node.conditions)
    }

    override func visitPost(_ node: StringLiteralExprSyntax) {
        guard node.openingQuote.tokenKind == .multilineStringQuote else { return }
        let start = node.positionAfterSkippingLeadingTrivia.utf8Offset
        let end = node.endPositionBeforeTrailingTrivia.utf8Offset
        let interpolationStarts = node.segments.compactMap { segment -> ByteCount? in
            guard case let .expressionSegment(expressionSegment) = segment else { return nil }
            return ByteCount(expressionSegment.backslash.positionAfterSkippingLeadingTrivia.utf8Offset)
        }
        spans.append(MultilineStringSpan(
            range: ByteRange(location: ByteCount(start), length: ByteCount(end - start)),
            interpolationStarts: interpolationStarts
        ))
    }

    private func collectContinuationLines(keyword: TokenSyntax, conditions: ConditionElementListSyntax) {
        guard conditions.count > 1 else { return }
        let keywordLine = locationConverter.location(for: keyword.positionAfterSkippingLeadingTrivia).line
        let firstConditionLoc = locationConverter.location(for: conditions.positionAfterSkippingLeadingTrivia)
        let conditionsEndLine = locationConverter.location(for: conditions.endPositionBeforeTrailingTrivia).line
        guard keywordLine < conditionsEndLine else { return }
        // Expected column is where the first condition starts (0-based → subtract 1)
        let expectedColumn = firstConditionLoc.column - 1
        for lineIndex in (keywordLine + 1)...conditionsEndLine {
            continuationLines[lineIndex] = expectedColumn
        }
    }
}
