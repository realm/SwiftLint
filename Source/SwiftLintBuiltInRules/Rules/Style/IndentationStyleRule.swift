import Foundation
import SourceKittenFramework

struct IndentationStyleRule: ConfigurationProviderRule, OptInRule {
    // MARK: - Subtypes
    private enum Indentation: Equatable {
        case tabs
        case spaces
    }

    // MARK: - Properties
    var configuration = IndentationStyleConfiguration()

    static let description = RuleDescription(
        identifier: "indentation_style",
        name: "Indentation Style",
        description: """
            Indent code using either tabs or spaces, not a chaotic mix. Can be configured to per file or project wide.
            """,
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                class Foo {
                    let tabLine = false
                    let spaceLine = true
                }
                """),
            Example("""
                class Foo {
                \tlet tabLine = true
                \tlet spaceLine = false
                }
                """),
            Example("""
                class Foo {
                \tlet tabLine = true
                \tlet spaceLine = false

                \tfunc barb(arg: String) {
                \t\tprint(arg)
                \t}
                }
                """),
            Example("""
                abcd(bar: "far",
                     baz: 0,
                     bat: false)
                """),
            Example("""
                abcd(
                    bar: "far",
                    baz: 0,
                    bat: false)
                """),
            Example("""
                abcd(bar: "far",
                \t baz: 0,
                \t bat: false)
                """),
            Example("""
                abcd(
                \tbar: "far",
                \tbaz: 0,
                \tbat: false)
                """),
            Example(
                """
                class Foo {
                \tlet multiLineString = \"""
                \t\tcontent
                \t\t    more content
                \t\t  most content
                \t\t  \ttabbed content
                \t\t\"""
                }
                """)
        ],
        triggeringExamples: [
            Example("""
                class Foo {
                \tlet tabLine = true
                ↓    let spaceLine = true
                }
                """),
            Example("""
                class Foo {
                \tlet tabLine = true
                \tlet spaceLine = false

                \tfunc barb(arg: String) {
                \t↓ \tprint(arg)
                \t}
                }
                """),
            Example("""
                class Foo {
                \tlet tabLine = true
                \tlet spaceLine = false

                \tfunc barb(arg: String) {
                \t↓ print(arg)
                \t}
                }
                """),
            Example("""
                class Foo {
                \tlet tabLine = true
                \tlet spaceLine = false

                \tfunc barb(arg: String) {
                ↓ \t\tprint(arg)
                \t}
                }
                """),

            Example("""
                abcd(bar: "far",
                \t baz: 0,
                ↓     bat: false)
                """),
            Example("""
                abcd(
                    bar: "far",
                ↓\tbaz: 0,
                ↓\tbat: false)
                """),
            Example(
                """
                abcd(bar: "far",
                \t↓     baz: 0,
                \t↓ bat: false)
                """,
                configuration: IndentationStyleConfiguration.testTabWidth),
            Example(
                """
                // - include_multiline_strings: true
                class Foo {
                \tlet multiLineString = \"""
                \t\tcontent
                \t\t    more content
                \t\t  most content
                \t\t  \ttabbed content
                \t\t\"""
                }
                """,
                configuration: IndentationStyleConfiguration.testMultilineString),
        ]
    )

    // MARK: - Initializers
    // MARK: - Methods: Validation
    func validate(file: SwiftLintFile) -> [StyleViolation] { // swiftlint:disable:this function_body_length
        var violations: [StyleViolation] = []

        var fileStyle: ConfigurationType.PreferredStyle?
        if configuration.perFile == false {
            fileStyle = configuration.preferredStyle
        }


        for line in file.lines {
            let indentationForThisLine = getIndentation(for: line)
            let indentationCharacterCount = indentationForThisLine.count

            guard indentationCharacterCount > 0 else { continue }

            if ignoreMultilineStrings(line: line, in: file) { continue }

            guard let firstLineIndentation = indentationForThisLine.first else { continue }

            let confirmedFileStyle: ConfigurationType.PreferredStyle
            if let fileStyle {
                confirmedFileStyle = fileStyle
            } else {
                switch firstLineIndentation {
                case " ":
                    fileStyle = .spaces
                    confirmedFileStyle = .spaces
                case "\t":
                    fileStyle = .tabs
                    confirmedFileStyle = .tabs
                default:
                    fatalError(
                        "Somehow a non tab or space made it into indentation: '\(firstLineIndentation)'" +
                        " aka \(firstLineIndentation.unicodeScalars)")
                }
            }

            switch confirmedFileStyle {
            case .spaces:
                if let offset = line.content.firstIndex(of: "\t") {
                    let intOffset = line.content.distance(from: line.content.startIndex, to: offset)

                    let violation = StyleViolation(
                        ruleDescription: Self.description,
                        severity: configuration.severity,
                        location: Location(file: file, characterOffset: line.range.location + intOffset),
                        reason: "Code should be indented with spaces\(configuration.perFile ? " (In this file)" : "")")
                    violations.append(violation)
                }
            case .tabs:
                if let offset = indentationForThisLine.firstIndex(of: " ") {
                    if
                        previousLineSetsNonstandardIndentationExpectation(line, in: file) &&
                        validateSpacesEnding(indentationForThisLine) {

                        continue
                    }

                    let intOffset = line.content.distance(from: line.content.startIndex, to: offset)
                    let violation = StyleViolation(
                        ruleDescription: Self.description,
                        severity: configuration.severity,
                        location: Location(file: file, characterOffset: line.range.location + intOffset),
                        reason: "Code should be indented with tabs\(configuration.perFile ? " (In this file)" : "")")
                    violations.append(violation)
                }
            }
        }

        return violations
    }

    private func ignoreMultilineStrings(line: Line, in file: SwiftLintFile) -> Bool {
        guard configuration.includeMultilineStrings == false else { return false }

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

    /// Allow for situations where the style is to keep the first method argument or array member on the same line as the call site.
    /// for example:
    /// ```swift
    /// func abcd(efg: String,
    ///           hijk: String)
    /// ```
    /// or
    /// ```swift
    /// let foo = [1,
    ///            2,
    ///            3]
    /// ```
    ///
    /// These don't necessarily line up nicely on the 2,3,4,8 space indentation or whatever tab width you have set.
    private func previousLineSetsNonstandardIndentationExpectation(_ currentLine: Line, in file: SwiftLintFile) -> Bool {
        guard
            currentLine.index > 1
        else { return false }

        let previousLine = file.lines[currentLine.index - 2]
        let currentLineIndentation = getIndentation(for: currentLine)
        let previousLineIndentation = getIndentation(for: previousLine) // 2 to compensate for 1-indexed value

        if currentLineIndentation == previousLineIndentation { return true }

        let openersAndClosers = Set("()[]")

        var openParens = 0
        var openSquares = 0

        for character in previousLine.content where openersAndClosers.contains(character) {
            switch character {
            case "(":
                openParens += 1
            case ")":
                openParens -= 1
            case "[":
                openSquares += 1
            case "]":
                openSquares -= 1
            default: continue
            }
        }

        return openParens > 0 || openSquares > 0
    }

    static private let indentationCharactersSet = Set(" \t")
    private func getIndentation(for line: Line) -> String.SubSequence {
        line.content.prefix(while: { Self.indentationCharactersSet.contains($0) })
    }

    /// Checks to make sure that in tab mode indentation, any spaces are only at the end and are, at most, tabWidth-1 in quantity, if tabWidth is set.
    private func validateSpacesEnding(_ indentation: String.SubSequence) -> Bool {
        guard indentation.first == "\t" else { return false }

        var spacesCount = 0
        for char in indentation {
            switch char {
            case "\t":
                guard spacesCount == 0 else { return false }
                continue
            case " ":
                spacesCount += 1
            default:
                fatalError("Somehow a non tab or space made it into indentation: '\(indentation)' aka \(indentation.unicodeScalars)")
            }
        }

        if
            let tabWidth = configuration.tabWidth,
            spacesCount >= tabWidth {

            return false
        }

        return true
    }
}
