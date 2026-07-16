import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftSyntax

struct IndentationWidthRule: OptInRule, SourceKitFreeRule {
    // MARK: - Subtypes
    private enum Indentation: Equatable {
        case tabs(Int)
        case spaces(Int)

        func spacesEquivalent(indentationWidth: Int) -> Int {
            switch self {
            case let .tabs(tabs): return tabs * indentationWidth
            case let .spaces(spaces): return spaces
            }
        }
    }

    /// Parsed information about a line's leading whitespace.
    private struct IndentationPrefix {
        let tabCount: Int
        let spaceCount: Int

        var combinedCount: Int { tabCount + spaceCount }

        init(line: Line, length: Int) {
            var tabs = 0
            var spaces = 0
            for char in line.content.prefix(length) {
                if char == "\t" { tabs += 1 } else if char == " " { spaces += 1 }
            }
            self.tabCount = tabs
            self.spaceCount = spaces
        }

        func spacesEquivalent(indentationWidth: Int) -> Int {
            spaceCount + tabCount * indentationWidth
        }
    }

    // MARK: - Properties
    var configuration = IndentationWidthConfiguration()

    static let description = RuleDescription(
        identifier: "indentation_width",
        name: "Indentation Width",
        description: "Indent code using either one tab or the configured amount of spaces, " +
            "unindent to match previous indentations. Don't indent the first line.",
        kind: .style,
        nonTriggeringExamples: #examples([
            "firstLine\nsecondLine",
            "firstLine\n    secondLine",
            "firstLine\n\tsecondLine\n\t\tthirdLine\n\n\t\tfourthLine",
            "firstLine\n\tsecondLine\n\t\tthirdLine\n\t//test\n\t\tfourthLine",
            "firstLine\n    secondLine\n        thirdLine\nfourthLine",
            """
                guard let x = foo(),
                      let y = bar() else {
                    return
                }
                """,
            """
                if let x = foo(),
                   let y = bar() {
                    doSomething()
                }
                """,
            """
                while let x = foo(),
                      let y = bar() {
                    doSomething()
                }
                """,
            """
                if let x = foo(),
                   let y = bar(),
                   let z = baz() {
                    doSomething()
                }
                """,
        ]),
        triggeringExamples: #examples([
            "↓    firstLine".asExample(testMultiByteOffsets: false, testDisableCommand: false),
            "firstLine\n        secondLine",
            "firstLine\n\tsecondLine\n\n↓\t\t\tfourthLine",
            "firstLine\n    secondLine\n        thirdLine\n↓ fourthLine",
        ]).skipWrappingInCommentTests()
    )

    // MARK: - Initializers
    // MARK: - Methods: Validation
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        var violations: [StyleViolation] = []
        var previousLineIndentations: [Indentation] = []

        let conditionContinuationInfo = multilineConditionInfo(in: file)
        let commentSpans = file.commentByteRanges()
        let stringSpans = multilineStringSpans(in: file)

        for line in file.lines {
            // Skip whitespace-only lines, comments, compiler directives, multiline strings
            let indentationCharacterCount = line.content.countOfLeadingCharacters(in: CharacterSet(charactersIn: " \t"))
            if shouldSkipLine(
                line: line,
                indentationCharacterCount: indentationCharacterCount,
                commentSpans: commentSpans,
                multilineStringSpans: stringSpans
            ) { continue }

            let prefix = IndentationPrefix(line: line, length: indentationCharacterCount)

            if let expectedColumn = conditionContinuationInfo[line.index] {
                if let violation = checkMultilineConditionAlignment(
                    line: line, expectedColumn: expectedColumn, prefix: prefix, file: file
                ) {
                    violations.append(violation)
                }
                continue
            }

            // Determine indentation from prefix
            let (indentation, mixedViolation) = parseIndentation(line: line, prefix: prefix, file: file)
            if let mixedViolation { violations.append(mixedViolation) }

            // Catch indented first line
            guard previousLineIndentations.isNotEmpty else {
                previousLineIndentations = [indentation]
                if indentation != .spaces(0) {
                    violations.append(
                        makeViolation(file: file, line: line, reason: "The first line shall not be indented")
                    )
                }
                continue
            }

            if let violation = checkIndentationChange(
                indentation: indentation, previousLineIndentations: previousLineIndentations, line: line, file: file
            ) {
                violations.append(violation)
            }

            if validate(indentation: indentation, comparingTo: previousLineIndentations[0]) {
                previousLineIndentations = [indentation]
            } else {
                previousLineIndentations.append(indentation)
            }
        }

        return violations
    }

    private func shouldSkipLine(
        line: Line,
        indentationCharacterCount: Int,
        commentSpans: [ByteRange],
        multilineStringSpans: [MultilineStringSpan]
    ) -> Bool {
        line.content.count == indentationCharacterCount ||
            ignoreCompilerDirective(line: line, indentationCharacterCount: indentationCharacterCount) ||
            ignoreComment(line: line, commentSpans: commentSpans) ||
            ignoreMultilineStrings(line: line, multilineStringSpans: multilineStringSpans)
    }

    private func checkIndentationChange(
        indentation: Indentation, previousLineIndentations: [Indentation], line: Line, file: SwiftLintFile
    ) -> StyleViolation? {
        let isValid = previousLineIndentations.contains { validate(indentation: indentation, comparingTo: $0) }
        guard !isValid else { return nil }
        let isIndentation = previousLineIndentations.last.map {
            indentation.spacesEquivalent(indentationWidth: configuration.indentationWidth) >=
                $0.spacesEquivalent(indentationWidth: configuration.indentationWidth)
        } ?? true
        let indentWidth = configuration.indentationWidth
        return makeViolation(
            file: file,
            line: line,
            reason: isIndentation ?
                "Code should be indented using one tab or \(indentWidth) spaces" :
                "Code should be unindented by multiples of one tab or multiples of \(indentWidth) spaces"
        )
    }

    private func makeViolation(file: SwiftLintFile, line: Line, reason: String) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severityConfiguration.severity,
            location: Location(file: file, characterOffset: line.range.location),
            reason: reason
        )
    }

    private func parseIndentation(
        line: Line, prefix: IndentationPrefix, file: SwiftLintFile
    ) -> (Indentation, StyleViolation?) {
        if prefix.tabCount != 0, prefix.spaceCount != 0 {
            let violation = makeViolation(
                file: file,
                line: line,
                reason: "Code should be indented with tabs or " +
                    "\(configuration.indentationWidth) spaces, but not both in the same line"
            )
            return (.spaces(prefix.spacesEquivalent(indentationWidth: configuration.indentationWidth)), violation)
        }
        if prefix.tabCount != 0 {
            return (.tabs(prefix.tabCount), nil)
        }
        return (.spaces(prefix.spaceCount), nil)
    }

    private func checkMultilineConditionAlignment(
        line: Line, expectedColumn: Int, prefix: IndentationPrefix, file: SwiftLintFile
    ) -> StyleViolation? {
        if !configuration.includeMultilineConditions { return nil }
        let actualColumn = prefix.spacesEquivalent(indentationWidth: configuration.indentationWidth)
        guard actualColumn != expectedColumn else { return nil }
        return makeViolation(
            file: file,
            line: line,
            reason: "Multi-line condition should be aligned with the first condition " +
                "(expected \(expectedColumn) spaces, got \(actualColumn))"
        )
    }

    /// Returns a mapping from line index to expected indentation column for continuation lines
    /// of multi-line conditions. When `include_multiline_conditions` is false, these lines are
    /// skipped entirely (expected column is still stored so the line is recognized as a continuation).
    private func multilineConditionInfo(in file: SwiftLintFile) -> [Int: Int] {
        let visitor = MultilineConditionLineVisitor(locationConverter: file.locationConverter)
        return visitor.walk(tree: file.syntaxTree, handler: \.continuationLines)
    }

    /// Returns the byte spans of all multiline string literals in the file, in source order.
    private func multilineStringSpans(in file: SwiftLintFile) -> [MultilineStringSpan] {
        let visitor = MultilineStringSpanVisitor(viewMode: .sourceAccurate)
        // `visitPost` yields nested literals before the literal containing them, so sort by location
        // and keep only outermost spans to uphold the binary search's sortedness invariant. Lines of
        // a nested literal are within the outer literal's span, which decides for the whole region.
        var spans = [MultilineStringSpan]()
        for span in visitor.walk(tree: file.syntaxTree, handler: \.spans).sorted(by: { $0.range.location < $1.range.location }) {
            if let last = spans.last, span.range.upperBound <= last.range.upperBound {
                continue
            }
            spans.append(span)
        }
        return spans
    }

    private static let compilerDirectiveKeywords = ["#if", "#elseif", "#else", "#endif"]

    private func ignoreCompilerDirective(line: Line, indentationCharacterCount: Int) -> Bool {
        if configuration.includeCompilerDirectives {
            return false
        }
        // A build configuration directive line starts with one of the `#if` family keywords after its
        // indentation. Directive-looking content inside a multiline string is also skipped by the
        // multiline string check, so treating it as a directive here doesn't change the outcome.
        let content = line.content.dropFirst(indentationCharacterCount)
        return Self.compilerDirectiveKeywords.contains { keyword in
            guard content.hasPrefix(keyword) else {
                return false
            }
            let next = content.dropFirst(keyword.count).first
            return next.map { !$0.isLetter && !$0.isNumber && $0 != "_" } ?? true
        }
    }

    private func ignoreComment(line: Line, commentSpans: [ByteRange]) -> Bool {
        if configuration.includeComments {
            return false
        }
        // The line is skipped when its non-whitespace content consists solely of comments, matching
        // the previous "every syntax token in the line is a comment kind" check. Comment extents come
        // from syntax tree trivia; bytes between or around them on the line must all be whitespace.
        let lineStart = line.byteRange.location.value
        var spanIndex = commentSpans.firstIndexAssumingSorted { $0.upperBound.value > lineStart } ?? commentSpans.count
        var sawComment = false
        var byteOffset = 0
        for byte in line.content.utf8 {
            defer { byteOffset += 1 }
            let position = lineStart + byteOffset
            while spanIndex < commentSpans.count, commentSpans[spanIndex].upperBound.value <= position {
                spanIndex += 1
            }
            if spanIndex < commentSpans.count,
               commentSpans[spanIndex].location.value <= position {
                sawComment = true
                continue
            }
            if byte != 0x20, byte != 0x09, byte != 0x0D {
                return false
            }
        }
        return sawComment
    }

    private func ignoreMultilineStrings(line: Line, multilineStringSpans: [MultilineStringSpan]) -> Bool {
        if configuration.includeMultilineStrings {
            return false
        }

        // A multiline string content line is characterized by starting strictly inside a string literal, just as it
        // began with a string token whose range's lower bound was smaller than that of the line itself in SourceKit's
        // syntax map.
        let lineRange = line.byteRange
        guard
            let spanIndex = multilineStringSpans.firstIndexAssumingSorted(
                where: { $0.range.upperBound > lineRange.lowerBound }
            ),
            multilineStringSpans[spanIndex].range.lowerBound < lineRange.lowerBound else {
            return false
        }
        let span = multilineStringSpans[spanIndex]

        // SourceKit split a literal's string token at interpolations: the token ended right before each `\(` and the
        // next one started right after the matching parenthesis. Mirror those boundaries for identical line decisions.
        if let interpolationStart = span.interpolationStarts.first(where: { $0 >= lineRange.lowerBound }) {
            if interpolationStart == lineRange.lowerBound {
                // The line starts at an interpolation's backslash, so its first token isn't a string token.
                return false
            }
            if interpolationStart < lineRange.upperBound {
                // An interpolation starts on this line, so the line contains more than one token.
                return true
            }
            // The string token beginning this line ends right before the next interpolation on a later line.
            return lineRange.upperBound < interpolationStart
        }

        // Closing delimiters of a multiline string should follow the defined indentation. The Swift compiler requires
        // those delimiters to be on their own line so the line is only skipped if the literal continues past it.
        return lineRange.upperBound < span.range.upperBound
    }

    /// Validates whether the indentation of a specific line is valid based on the indentation of the previous line.
    ///
    /// - parameter indentation:     The indentation of the line to validate.
    /// - parameter lastIndentation: The indentation of the previous line.
    ///
    /// - returns: Whether the specified indentation is valid.
    private func validate(indentation: Indentation, comparingTo lastIndentation: Indentation) -> Bool {
        let currentSpaceEquivalent = indentation.spacesEquivalent(indentationWidth: configuration.indentationWidth)
        let lastSpaceEquivalent = lastIndentation.spacesEquivalent(indentationWidth: configuration.indentationWidth)

        return (
            // Allow indent by indentationWidth
            currentSpaceEquivalent == lastSpaceEquivalent + configuration.indentationWidth ||
            (
                (lastSpaceEquivalent - currentSpaceEquivalent) >= 0 &&
                (lastSpaceEquivalent - currentSpaceEquivalent).isMultiple(of: configuration.indentationWidth)
            ) // Allow unindent if it stays in the grid
        )
    }
}

private final class MultilineConditionLineVisitor: SyntaxVisitor {
    private let locationConverter: SourceLocationConverter
    /// Maps line index → expected indentation column for continuation lines.
    private(set) var continuationLines = [Int: Int]()

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

/// The extent of a multiline string literal, matching the extent of the literal's string token in SourceKit's syntax
/// map: it covers everything from the first opening delimiter to the end of the closing delimiter.
private struct MultilineStringSpan {
    let range: ByteRange
    /// The byte offsets of the backslashes introducing the literal's interpolation segments.
    let interpolationStarts: [ByteCount]
}

private final class MultilineStringSpanVisitor: SyntaxVisitor {
    /// The spans of all multiline string literals in the file, in source order.
    private(set) var spans = [MultilineStringSpan]()

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
}
