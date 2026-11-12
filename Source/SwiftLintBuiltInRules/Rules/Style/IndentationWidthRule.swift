import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftSyntax

@DisabledWithoutSourceKit
struct IndentationWidthRule: OptInRule {
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
            "func f() {\n    if ready {\n    }\n}",
            "func f() {\n    switch value {\n    case .ready: work()\n    }\n}",
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
            "func f() {\n    if ready {\n        work()\n↓}\n}",
        ]).skipWrappingInCommentTests()
    )

    // MARK: - Initializers
    // MARK: - Methods: Validation
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        var violations: [StyleViolation] = []
        var previousLineIndentations: [Indentation] = []

        let lineInfo = indentationLineInfo(in: file)

        for line in file.lines {
            // Skip whitespace-only lines, comments, compiler directives, multiline strings
            let indentationCharacterCount = line.content.countOfLeadingCharacters(in: CharacterSet(charactersIn: " \t"))
            if shouldSkipLine(line: line, indentationCharacterCount: indentationCharacterCount, in: file) { continue }

            let prefix = IndentationPrefix(line: line, length: indentationCharacterCount)

            if let expectedColumn = lineInfo.continuationLines[line.index] {
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

            if let closingBrace = lineInfo.closingBraces[line.byteRange.location],
               let violation = checkClosingBraceIndentation(prefix: prefix, closingBrace: closingBrace, file: file) {
                violations.append(violation)
            } else if let violation = checkIndentationChange(
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

    private func checkClosingBraceIndentation(
        prefix: IndentationPrefix, closingBrace: (line: Int, indentation: Int), file: SwiftLintFile
    ) -> StyleViolation? {
        let actualIndentation = prefix.spacesEquivalent(indentationWidth: configuration.indentationWidth)
        guard actualIndentation < closingBrace.indentation else {
            return nil
        }
        return StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severityConfiguration.severity,
            location: Location(file: file.path, line: closingBrace.line, character: 1),
            reason: "Closing brace should be aligned with its opening declaration or statement"
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

    private func indentationLineInfo(in file: SwiftLintFile) -> IndentationLineVisitor {
        let visitor = IndentationLineVisitor(
            locationConverter: file.locationConverter, indentationWidth: configuration.indentationWidth
        )
        return visitor.walk(tree: file.syntaxTree, handler: { $0 })
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
}

private final class IndentationLineVisitor: SyntaxVisitor {
    private let locationConverter: SourceLocationConverter
    private let indentationWidth: Int
    /// Maps line index → expected indentation column for continuation lines.
    private(set) var continuationLines = [Int: Int]()
    /// Byte offsets keep SwiftSyntax and SourceKitten lines consistent for both LF and CRLF.
    private(set) var closingBraces = [ByteCount: (line: Int, indentation: Int)]()

    init(locationConverter: SourceLocationConverter, indentationWidth: Int) {
        self.locationConverter = locationConverter
        self.indentationWidth = indentationWidth
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

    override func visitPost(_ node: CodeBlockSyntax) {
        collectClosingBrace(node.rightBrace, anchor: node.parent?.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: MemberBlockSyntax) {
        collectClosingBrace(node.rightBrace, anchor: node.parent?.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: AccessorBlockSyntax) {
        let declaration = node.parent?.as(PatternBindingSyntax.self)?.parent?.parent?.as(VariableDeclSyntax.self)
        collectClosingBrace(
            node.rightBrace,
            anchor: declaration?.positionAfterSkippingLeadingTrivia ?? node.parent?.positionAfterSkippingLeadingTrivia
        )
    }

    override func visitPost(_ node: SwitchExprSyntax) {
        collectClosingBrace(node.rightBrace, anchor: node.switchKeyword.positionAfterSkippingLeadingTrivia)
    }

    private func collectClosingBrace(_ brace: TokenSyntax, anchor: AbsolutePosition?) {
        guard brace.presence == .present, let anchor else { return }
        let location = locationConverter.location(for: brace.positionAfterSkippingLeadingTrivia)
        let anchorLine = locationConverter.location(for: anchor).line
        guard anchorLine < location.line,
              locationConverter.sourceLines[location.line - 1].utf8.prefix(location.column - 1)
                .allSatisfy({ $0 == 32 || $0 == 9 }) else { return }
        // A preceding line may close several nested blocks, contain an empty body, or be
        // a switch case/continuation. Its indentation does not identify this brace's owner.
        // Closures retain the existing grid checks; closure_end_indentation handles their anchors.
        let prefix = locationConverter.sourceLines[anchorLine - 1].prefix(while: { $0 == " " || $0 == "\t" })
        let indentation = prefix.reduce(0) { $0 + ($1 == "\t" ? indentationWidth : 1) }
        // An invalid opener is already reported by the grid/mixed-indentation checks.
        // Do not make its otherwise correctly indented closing brace a cascading violation.
        guard indentation.isMultiple(of: indentationWidth),
              !prefix.contains(" ") || !prefix.contains("\t") else { return }
        let lineOffset = brace.positionAfterSkippingLeadingTrivia.utf8Offset - location.column + 1
        closingBraces[ByteCount(lineOffset)] = (location.line, indentation)
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
