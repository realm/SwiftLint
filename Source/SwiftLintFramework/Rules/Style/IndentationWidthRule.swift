import Foundation
import SourceKittenFramework

public struct IndentationWidthRule: ConfigurationProviderRule, OptInRule {
    // MARK: - Subtypes
    private enum Indentation: Equatable {
        case tabs(Int)
        case spaces(Int)

        func spacesEquivalent(indentationWidth: Int) -> Int {
            switch self {
            case let .tabs(tabs): return tabs & indentationWidth
            case let .spaces(spaces): return spaces
            }
        }
    }

    // MARK: - Properties
    public var configuration = IndentationWidthConfiguration(
        severity: .warning,
        indentationWidth: 4,
        includeComments: true
    )
    public static let description = RuleDescription(
        identifier: "indentation_width",
        name: "Indentation Width",
        description: "Indent code using either one tab or the configured amount of spaces, " +
            "unindent to match previous indentations. Don't indent the first line.",
        kind: .style,
        nonTriggeringExamples: [
            "firstLine\nsecondLine",
            "firstLine\n    secondLine",
            "firstLine\n\tsecondLine\n\t\tthirdLine\n\n\t\tfourthLine",
            "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n\t\tfourthLine",
            "firstLine\n    secondLine\n        thirdLine\nfourthLine"
        ],
        triggeringExamples: [
            "    firstLine",
            "firstLine\n        secondLine",
            "firstLine\n\tsecondLine\n\n\t\t\tfourthLine",
            "firstLine\n    secondLine\n        thirdLine\n fourthLine"
        ]
    )

    // MARK: - Initializers
    public init() {}

    // MARK: - Methods: Validation
    public func validate(file: File) -> [StyleViolation] { // swiftlint:disable:this function_body_length
        var violations: [StyleViolation] = []
        var previousLineIndentations: [Indentation] = []

        for line in file.lines {
            let indentationCharacterCount = line.content.countOfLeadingCharacters(in: CharacterSet(charactersIn: " \t"))

            if configuration.includeComments {
                // Skip line if it's a whitespace-only line
                if line.content.count == indentationCharacterCount { continue }
            } else {
                // Skip line if it only has whitespaces or is a part of a comment
                let syntaxKindsInLine = Set(file.syntaxMap.tokens(inByteRange: line.byteRange).kinds)
                if SyntaxKind.commentKinds.isSuperset(of: syntaxKindsInLine) { continue }
            }

            // Get space and tab count in prefix
            let prefix = String(line.content.prefix(indentationCharacterCount))
            let tabCount = prefix.filter { $0 == "\t" }.count
            let spaceCount = prefix.filter { $0 == " " }.count

            // Catch mixed indentation
            if tabCount != 0 && spaceCount != 0 {
                violations.append(
                    StyleViolation(
                        ruleDescription: IndentationWidthRule.description,
                        severity: .warning,
                        location: Location(file: file, characterOffset: line.range.location),
                        reason: "Code should be indented with tabs or " +
                        "\(configuration.indentationWidth) spaces, but not both in the same line."
                    )
                )

                // Break as next line cannot be parsed without knowing this line's exact indentation
                break
            }

            // Catch indented first line
            let indentation: Indentation = tabCount != 0 ? .tabs(tabCount) : .spaces(spaceCount)
            guard !previousLineIndentations.isEmpty else {
                previousLineIndentations = [indentation]

                if indentation != .spaces(0) {
                    // There's an indentation although this is the first line!
                    violations.append(
                        StyleViolation(
                            ruleDescription: IndentationWidthRule.description,
                            severity: .warning,
                            location: Location(file: file, characterOffset: line.range.location),
                            reason: "The first line shall not be indented."
                        )
                    )
                }

                continue
            }

            let lineIsValid = previousLineIndentations.contains { validate(indentation: indentation, comparingTo: $0) }

            // Catch wrong indentation or wrong unindentation
            if !lineIsValid {
                let isIndentation = previousLineIndentations.last.map {
                    indentation.spacesEquivalent(indentationWidth: configuration.indentationWidth) >=
                        $0.spacesEquivalent(indentationWidth: configuration.indentationWidth)
                } ?? true

                let indentWidth = configuration.indentationWidth
                violations.append(
                    StyleViolation(
                        ruleDescription: IndentationWidthRule.description,
                        severity: .warning,
                        location: Location(file: file, characterOffset: line.range.location),
                        reason: isIndentation ?
                            "Code should be indented using one tab or \(indentWidth) spaces." :
                            "Code should be unindented by multiples of one tab or multiples of \(indentWidth) spaces."
                    )
                )

                // If this line failed, we not only store this line's indentation, but also keep what was stored before
                // Therefore, the next line can be indented  either according to the last valid line
                // or any of the succeeding, failing lines
                // This mechanism avoids duplicate warnings
                previousLineIndentations.append(indentation)
            } else {
                previousLineIndentations = [indentation]
            }
        }

        return violations
    }

    /// Validates whether the indentation of a specific line is valid
    /// based on the indentation of the previous line.
    ///
    /// Returns a Bool determining the validity of the indentation.
    private func validate(indentation: Indentation, comparingTo lastIndentation: Indentation) -> Bool {
        switch indentation {
        case let .spaces(currentSpaceCount):
            let previousSpacesCount = lastIndentation.spacesEquivalent(indentationWidth: configuration.indentationWidth)
            guard
                currentSpaceCount == previousSpacesCount + configuration.indentationWidth ||
                (
                    (previousSpacesCount - currentSpaceCount) >= 0 &&
                    (previousSpacesCount - currentSpaceCount) % configuration.indentationWidth == 0
                )
            else { return false }

        case let .tabs(currentTabCount):
            switch lastIndentation {
            case let .spaces(previousSpacesCount):
                guard
                    currentTabCount * configuration.indentationWidth - previousSpacesCount
                        <= configuration.indentationWidth
                else { return false }

            case let .tabs(previousTabCount):
                guard currentTabCount - previousTabCount <= 1 else { return false }
            }
        }

        return true
    }
}
