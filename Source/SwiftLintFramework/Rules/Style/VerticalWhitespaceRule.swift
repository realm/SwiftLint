import Foundation
import SourceKittenFramework

private let defaultDescriptionReason = "Limit vertical whitespace to a single empty line"

struct VerticalWhitespaceRule: CorrectableRule, ConfigurationProviderRule {
    var configuration = VerticalWhitespaceConfiguration(maxEmptyLines: 1)

    init() {}

    static let description = RuleDescription(
        identifier: "vertical_whitespace",
        name: "Vertical Whitespace",
        description: defaultDescriptionReason + ".",
        kind: .style,
        nonTriggeringExamples: [
            Example("let abc = 0\n"),
            Example("let abc = 0\n\n"),
            Example("/* bcs \n\n\n\n*/"),
            Example("// bca \n\n")
        ],
        triggeringExamples: [
            Example("let aaaa = 0\n\n\n"),
            Example("struct AAAA {}\n\n\n\n"),
            Example("class BBBB {}\n\n\n")
        ],
        corrections: [
            Example("let b = 0\n\n\nclass AAA {}\n"): Example("let b = 0\n\nclass AAA {}\n"),
            Example("let c = 0\n\n\nlet num = 1\n"): Example("let c = 0\n\nlet num = 1\n"),
            Example("// bca \n\n\n"): Example("// bca \n\n")
        ] // End of line autocorrections are handled by Trailing Newline Rule.
    )

    private var configuredDescriptionReason: String {
        guard configuration.maxEmptyLines == 1 else {
            return "Limit vertical whitespace to maximum \(configuration.maxEmptyLines) empty lines"
        }
        return defaultDescriptionReason
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let linesSections = violatingLineSections(in: file)
        guard linesSections.isNotEmpty else {
            return []
        }

        return linesSections.map { eachLastLine, eachSectionCount in
            return StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severityConfiguration.severity,
                location: Location(file: file.path, line: eachLastLine.index),
                reason: configuredDescriptionReason + "; currently \(eachSectionCount + 1)"
            )
        }
    }

    private typealias LineSection = (lastLine: Line, linesToRemove: Int)

    private func violatingLineSections(in file: SwiftLintFile) -> [LineSection] {
        let nonSpaceRegex = regex("\\S", options: [])
        let filteredLines = file.lines.filter {
            nonSpaceRegex.firstMatch(in: file.contents, options: [], range: $0.range) == nil
        }

        guard filteredLines.isNotEmpty else {
            return []
        }

        let blankLinesSections = extractSections(from: filteredLines)

        // filtering out violations in comments and strings
        let stringAndComments = SyntaxKind.commentAndStringKinds
        let syntaxMap = file.syntaxMap
        let result = blankLinesSections.compactMap { eachSection -> (lastLine: Line, linesToRemove: Int)? in
            guard let lastLine = eachSection.last else {
                return nil
            }
            let kindInSection = syntaxMap.kinds(inByteRange: lastLine.byteRange)
            if stringAndComments.isDisjoint(with: kindInSection) {
                return (lastLine, eachSection.count)
            }

            return nil
        }

        return result.filter { $0.linesToRemove >= configuration.maxEmptyLines }
    }

    private func extractSections(from lines: [Line]) -> [[Line]] {
        var blankLinesSections = [[Line]]()
        var lineSection = [Line]()

        var previousIndex = 0
        for (index, line) in lines.enumerated() {
            let previousLine: Line = lines[previousIndex]
            if previousLine.index + 1 == line.index {
                lineSection.append(line)
            } else if lineSection.isNotEmpty {
                blankLinesSections.append(lineSection)
                lineSection.removeAll()
            }
            previousIndex = index
        }
        if lineSection.isNotEmpty {
            blankLinesSections.append(lineSection)
        }

        return blankLinesSections
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let linesSections = violatingLineSections(in: file)
        if linesSections.isEmpty { return [] }

        var indexOfLinesToDelete = [Int]()

        for section in linesSections {
            let linesToRemove = section.linesToRemove - configuration.maxEmptyLines + 1
            let start = section.lastLine.index - linesToRemove
            indexOfLinesToDelete.append(contentsOf: start..<section.lastLine.index)
        }

        var correctedLines = [String]()
        var corrections = [Correction]()
        for currentLine in file.lines {
            // Doesn't correct lines where rule is disabled
            if file.ruleEnabled(violatingRanges: [currentLine.range], for: self).isEmpty {
                correctedLines.append(currentLine.content)
                continue
            }

            // removes lines by skipping them from correctedLines
            if Set(indexOfLinesToDelete).contains(currentLine.index) {
                let description = Self.description
                let location = Location(file: file, characterOffset: currentLine.range.location)

                // reports every line that is being deleted
                corrections.append(Correction(ruleDescription: description, location: location))
                continue // skips line
            }

            // all lines that pass get added to final output file
            correctedLines.append(currentLine.content)
        }
        // converts lines back to file and adds trailing line
        if corrections.isNotEmpty {
            file.write(correctedLines.joined(separator: "\n") + "\n")
            return corrections
        }
        return []
    }
}
