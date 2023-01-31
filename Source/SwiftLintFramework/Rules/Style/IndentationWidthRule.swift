import Foundation
import SourceKittenFramework

struct IndentationWidthRule: ConfigurationProviderRule, OptInRule {
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

    // MARK: - Properties
    var configuration = IndentationWidthConfiguration(
        severity: .warning,
        indentationWidth: 4,
        includeComments: true,
        includeCompilerDirectives: true
    )
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
            Example("firstLine\n    secondLine\n        thirdLine\nfourthLine")
        ],
        triggeringExamples: [
            Example("↓    firstLine", testMultiByteOffsets: false, testDisableCommand: false),
            Example("firstLine\n        secondLine"),
            Example("firstLine\n\tsecondLine\n\n↓\t\t\tfourthLine"),
            Example("firstLine\n    secondLine\n        thirdLine\n↓ fourthLine")
        ].skipWrappingInCommentTests()
    )

    // MARK: - Initializers
    init() {}

    // MARK: - Methods: Validation
    func validate(file: SwiftLintFile) -> [StyleViolation] { // swiftlint:disable:this function_body_length
        var violations: [StyleViolation] = []
        var previousLineIndentations: [Indentation] = []

        for line in file.lines {
            if ignoreCompilerDirective(line: line, in: file) { continue }

            // Skip line if it's a whitespace-only line
            let indentationCharacterCount = line.content.countOfLeadingCharacters(in: CharacterSet(charactersIn: " \t"))
            if line.content.count == indentationCharacterCount { continue }

            if ignoreComment(line: line, in: file) { continue }

            // Get space and tab count in prefix
            let prefix = String(line.content.prefix(indentationCharacterCount))
            let tabCount = prefix.filter { $0 == "\t" }.count
            let spaceCount = prefix.filter { $0 == " " }.count

            // Determine indentation
            let indentation: Indentation
            if tabCount != 0 && spaceCount != 0 {
                // Catch mixed indentation
                violations.append(
                    StyleViolation(
                        ruleDescription: Self.description,
                        severity: configuration.severityConfiguration.severity,
                        location: Location(file: file, characterOffset: line.range.location),
                        reason: "Code should be indented with tabs or " +
                        "\(configuration.indentationWidth) spaces, but not both in the same line"
                    )
                )

                // Model this line's indentation using spaces (although it's tabs & spaces) to let parsing continue
                indentation = .spaces(spaceCount + tabCount * configuration.indentationWidth)
            } else if tabCount != 0 {
                indentation = .tabs(tabCount)
            } else {
                indentation = .spaces(spaceCount)
            }

            // Catch indented first line
            guard previousLineIndentations.isNotEmpty else {
                previousLineIndentations = [indentation]

                if indentation != .spaces(0) {
                    // There's an indentation although this is the first line!
                    violations.append(
                        StyleViolation(
                            ruleDescription: Self.description,
                            severity: configuration.severityConfiguration.severity,
                            location: Location(file: file, characterOffset: line.range.location),
                            reason: "The first line shall not be indented"
                        )
                    )
                }

                continue
            }

            let linesValidationResult = previousLineIndentations.map {
                validate(indentation: indentation, comparingTo: $0)
            }

            // Catch wrong indentation or wrong unindentation
            if !linesValidationResult.contains(true) {
                let isIndentation = previousLineIndentations.last.map {
                    indentation.spacesEquivalent(indentationWidth: configuration.indentationWidth) >=
                        $0.spacesEquivalent(indentationWidth: configuration.indentationWidth)
                } ?? true

                let indentWidth = configuration.indentationWidth
                violations.append(
                    StyleViolation(
                        ruleDescription: Self.description,
                        severity: configuration.severityConfiguration.severity,
                        location: Location(file: file, characterOffset: line.range.location),
                        reason: isIndentation ?
                            "Code should be indented using one tab or \(indentWidth) spaces" :
                            "Code should be unindented by multiples of one tab or multiples of \(indentWidth) spaces"
                    )
                )
            }

            if linesValidationResult.first == true {
                // Reset previousLineIndentations to this line only
                // if this line's indentation matches the last valid line's indentation (first in the array)
                previousLineIndentations = [indentation]
            } else {
                // We not only store this line's indentation, but also keep what was stored before.
                // Therefore, the next line can be indented either according to the last valid line
                // or any of the succeeding, failing lines.
                // This mechanism avoids duplicate warnings.
                previousLineIndentations.append(indentation)
            }
        }

        return violations
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
