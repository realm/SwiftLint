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
    public var configuration = IndentationWidthConfiguration(severity: .warning, indentationWidth: 4)
    public static let description = RuleDescription(
        identifier: "indentation_width",
        name: "Indentation Width",
        description: "Indent code using either one tab or the configured amount of spaces, " +
            "unindent to match previous indentations. Don't indent the first line.",
        kind: .style,
        nonTriggeringExamples: [
            "firstLine\nsecondLine", // It's okay to keep the same indentation
            "firstLine\n    secondLine", // It's okay to indent using the specified indentationWidth
            "firstLine\n\tsecondLine", // It's okay to indent using a tab
            "firstLine\n\tsecondLine\n\t\tthirdLine\n\n\t\tfourthLine", // It's okay to have empty lines between
            "firstLine\n\tsecondLine\n\t\tthirdLine\n \n\t\tfourthLine", // It's okay to have empty lines between
            "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n\t\tfourthLine", // It's okay to have comment lines between
            "firstLine\n    secondLine\n        thirdLine\nfourthLine"
            // It's okay to unindent indentationWidth * (1, 2, 3, ...)
        ],
        triggeringExamples: [
            "firstLine\n\t    secondLine", // It's not okay to indent using both tabs and spaces in one line
            "    firstLine", // It's not okay to have the first line indented
            "firstLine\n        secondLine", // It's not okay to indent using neither one tab or indentationWidth spaces
            "firstLine\n\t\tsecondLine", // It's not okay to indent using multiple tabs
            "firstLine\n\tsecondLine\n\n\t\t\tfourthLine",
            // It's okay to have empty lines between, but then, the following indentation must obey the rules
            "firstLine\n    secondLine\n        thirdLine\n fourthLine"
            // It's not okay to unindent indentationWidth * (1, 2, 3, ...) - 3
        ]
    )

    // MARK: - Initializers
    public init() {}

    // MARK: - Methods: Validation
    public func validate(file: File) -> [StyleViolation] { // swiftlint:disable:this function_body_length
        var violations: [StyleViolation] = []
        var previousLineIndentation: Indentation?

        for line in file.lines {
            let indentationCharacterCount = line.content.countOfLeadingCharacters(in: CharacterSet(charactersIn: " \t"))

            // Skip line if it's a whitespace or comment line
            if line.content.count == indentationCharacterCount || line.content.prefix(2) == "//" { continue }

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
            guard let lastIndentation = previousLineIndentation else {
                previousLineIndentation = indentation

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

            // Catch wrong indentation or wrong unindentation
            if !validate(indentation: indentation, comparingTo: lastIndentation) {
                let isIndentation = indentation.spacesEquivalent(indentationWidth: configuration.indentationWidth) >=
                    lastIndentation.spacesEquivalent(indentationWidth: configuration.indentationWidth)

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
            } else {
                // Only store if validation went well, avoids a duplicate warning in consequential lines
                previousLineIndentation = indentation
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
