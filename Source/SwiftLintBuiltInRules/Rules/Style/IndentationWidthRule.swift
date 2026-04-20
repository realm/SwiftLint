import Foundation
import SourceKittenFramework
import SwiftSyntax

@DisabledWithoutSourceKit
struct IndentationWidthRule: OptInRule, CorrectableRule {
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
        nonTriggeringExamples: [
            Example("firstLine\nsecondLine"),
            Example("firstLine\n    secondLine"),
            Example("firstLine\n\tsecondLine\n\t\tthirdLine\n\n\t\tfourthLine"),
            Example("firstLine\n\tsecondLine\n\t\tthirdLine\n\t//test\n\t\tfourthLine"),
            Example("firstLine\n    secondLine\n        thirdLine\nfourthLine"),
            Example("""
                guard let x = foo(),
                      let y = bar() else {
                    return
                }
                """),
            Example("""
                if let x = foo(),
                   let y = bar() {
                    doSomething()
                }
                """),
            Example("""
                while let x = foo(),
                      let y = bar() {
                    doSomething()
                }
                """),
            Example("""
                if let x = foo(),
                   let y = bar(),
                   let z = baz() {
                    doSomething()
                }
                """),
        ],
        triggeringExamples: [
            Example("↓    firstLine", testMultiByteOffsets: false, testDisableCommand: false),
            Example("firstLine\n        secondLine"),
            Example("firstLine\n\tsecondLine\n\n↓\t\t\tfourthLine"),
            Example("firstLine\n    secondLine\n        thirdLine\n↓ fourthLine"),
        ].skipWrappingInCommentTests()
    )

    // MARK: - Initializers
    // MARK: - Methods: Validation
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        var violations: [StyleViolation] = []
        var previousLineIndentations: [Indentation] = []

        let conditionContinuationInfo = multilineConditionInfo(in: file)

        for line in file.lines {
            // Skip whitespace-only lines, comments, compiler directives, multiline strings
            let indentationCharacterCount = line.content.countOfLeadingCharacters(in: CharacterSet(charactersIn: " \t"))
            if shouldSkipLine(line: line, indentationCharacterCount: indentationCharacterCount, in: file) { continue }

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

    private func shouldSkipLine(line: Line, indentationCharacterCount: Int, in file: SwiftLintFile) -> Bool {
        line.content.count == indentationCharacterCount ||
            ignoreCompilerDirective(line: line, in: file) ||
            ignoreComment(line: line, in: file) ||
            ignoreMultilineStrings(line: line, in: file)
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

    private func ignoreCompilerDirective(line: Line, in file: SwiftLintFile) -> Bool {
        if configuration.includeCompilerDirectives {
            return false
        }
        if file.syntaxMap.tokens(inByteRange: line.byteRange).kinds.first == .buildconfigKeyword {
            return true
        }
        return false
    }

    private func ignoreComment(line: Line, in file: SwiftLintFile) -> Bool {
        if configuration.includeComments {
            return false
        }
        let syntaxKindsInLine = Set(file.syntaxMap.tokens(inByteRange: line.byteRange).kinds)
        if syntaxKindsInLine.isNotEmpty, SyntaxKind.commentKinds.isSuperset(of: syntaxKindsInLine) {
            return true
        }
        return false
    }

    private func ignoreMultilineStrings(line: Line, in file: SwiftLintFile) -> Bool {
        if configuration.includeMultilineStrings {
            return false
        }

        // A multiline string content line is characterized by beginning with a token of kind string whose range's lower
        // bound is smaller than that of the line itself.
        let tokensInLine = file.syntaxMap.tokens(inByteRange: line.byteRange)
        guard
            let firstToken = tokensInLine.first,
            firstToken.kind == .string,
            firstToken.range.lowerBound < line.byteRange.lowerBound else {
            return false
        }

        // Closing delimiters of a multiline string should follow the defined indentation. The Swift compiler requires
        // those delimiters to be on their own line so we need to consider the number of tokens as well as the upper
        // bounds.
        return tokensInLine.count > 1 || line.byteRange.upperBound < firstToken.range.upperBound
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

    // MARK: - Methods: Correction
    func correct(file: SwiftLintFile) -> Int {
        var corrections = 0
        var previousLineIndentations: [Indentation] = []
        var correctedLines = file.lines.map(\.content)

        for (lineIndex, line) in file.lines.enumerated() {
            corrections += correctLine(
                at: lineIndex,
                line: line,
                file: file,
                in: &correctedLines,
                trackingIndentations: &previousLineIndentations
            )
        }

        if corrections > 0 {
            let correctedContent = correctedLines.joined(separator: "\n")
            file.write(correctedContent)
        }

        return corrections
    }

    private func correctLine(
        at lineIndex: Int,
        line: Line,
        file: SwiftLintFile,
        in correctedLines: inout [String],
        trackingIndentations previousLineIndentations: inout [Indentation]
    ) -> Int {
        if ignoreCompilerDirective(line: line, in: file) { return 0 }
        let indentationCharacterCount = line.content.countOfLeadingCharacters(in: CharacterSet(charactersIn: " \t"))
        if line.content.count == indentationCharacterCount { return 0 }
        if ignoreComment(line: line, in: file) || ignoreMultilineStrings(line: line, in: file) { return 0 }

        let prefix = String(line.content.prefix(indentationCharacterCount))
        let tabCount = prefix.filter { $0 == "\t" }.count
        let spaceCount = prefix.filter { $0 == " " }.count

        if tabCount != 0, spaceCount != 0 { return 0 }

        let indentation: Indentation = tabCount != 0 ? .tabs(tabCount) : .spaces(spaceCount)

        guard previousLineIndentations.isNotEmpty else {
            previousLineIndentations = [indentation]
            if indentation != .spaces(0) {
                correctedLines[lineIndex] = String(line.content.dropFirst(indentationCharacterCount))
                return 1
            }
            return 0
        }

        let linesValidationResult = previousLineIndentations.map {
            validate(indentation: indentation, comparingTo: $0)
        }

        if linesValidationResult.contains(true) {
            if linesValidationResult.first == true {
                previousLineIndentations = [indentation]
            } else {
                previousLineIndentations.append(indentation)
            }
            return 0
        }

        guard let lastValidIndentation = previousLineIndentations.first else { return 0 }

        let correctIndentLevel = lastValidIndentation.spacesEquivalent(indentationWidth: configuration.indentationWidth)
        let shouldUseTabs = tabCount > 0
        let correctIndent = generateIndentation(spaceCount: correctIndentLevel, usesTabs: shouldUseTabs)
        let lineContent = String(line.content.dropFirst(indentationCharacterCount))
        correctedLines[lineIndex] = correctIndent + lineContent

        let correctedIndentation: Indentation = shouldUseTabs
            ? .tabs(correctIndent.filter { $0 == "\t" }.count)
            : .spaces(correctIndent.filter { $0 == " " }.count)
        previousLineIndentations = [correctedIndentation]

        return 1
    }

    /// Generates an indentation string based on the number of spaces and whether tabs should be used.
    ///
    /// - parameter spaceCount: The number of space-equivalents needed.
    /// - parameter usesTabs:   Whether the indentation should use tabs.
    ///
    /// - returns: The generated indentation string.
    private func generateIndentation(spaceCount: Int, usesTabs: Bool) -> String {
        if usesTabs {
            let tabCount = spaceCount / configuration.indentationWidth
            let remainingSpaces = spaceCount % configuration.indentationWidth
            return String(repeating: "\t", count: tabCount) + String(repeating: " ", count: remainingSpaces)
        }
        return String(repeating: " ", count: spaceCount)
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
