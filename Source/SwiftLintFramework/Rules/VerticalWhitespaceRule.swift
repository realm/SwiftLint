//
//  VerticalWhitespaceRule.swift
//  SwiftLint
//
//  Created by J. Cheyo Jimenez on 2015-05-16.
//  Copyright (c) 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let descriptionReason = "Limit vertical whitespace to a single empty line."

public struct VerticalWhitespaceRule: CorrectableRule,
                                      ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "vertical_whitespace",
        name: "Vertical Whitespace",
        description: descriptionReason,
        nonTriggeringExamples: [
            "let abc = 0\n",
            "let abc = 0\n\n",
            "/* bcs \n\n\n\n*/",
            "// bca \n\n",
        ],
        triggeringExamples: [
            "let aaaa = 0\n\n\n",
            "struct AAAA {}\n\n\n\n",
             "class BBBB {}\n\n\n",
        ],
        corrections: [
            "let b = 0\n\n\nclass AAA {}\n": "let b = 0\n\nclass AAA {}\n",
            "let c = 0\n\n\nlet num = 1\n": "let c = 0\n\nlet num = 1\n",
            "// bca \n\n\n": "// bca \n\n",
        ] // End of line autocorrections are handled by Trailing Newline Rule.
    )

    public func validateFile(file: File) -> [StyleViolation] {

        let linesSections = validate(file)
        if linesSections.isEmpty { return [] }

        var violations = [StyleViolation]()
        for (eachLastLine, eachSectionCount) in linesSections {

            // Skips violations for areas where the rule is disabled
            if !file.ruleEnabledViolatingRanges([eachLastLine.range], forRule: self).isEmpty {
                let violation = StyleViolation(ruleDescription: self.dynamicType.description,
                                           severity: configuration.severity,
                                           location: Location(file: file.path,
                                            line: eachLastLine.index ),
                                           reason: descriptionReason
                                            + " Currently \(eachSectionCount + 1)." )
                violations.append(violation)
            }
        }
        return violations
    }

    func validate(file: File) -> [(lastLine: Line, linesToRemove: Int)] {

        let filteredLines = file.lines.filter {
            $0.content.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()).isEmpty
        }

        if filteredLines.isEmpty { return [] }

        var blankLinesSections = [[Line]]()
        var lineSection = [Line]()

        var previousIndex = 0
        for index in 0..<filteredLines.count {
            if filteredLines[previousIndex].index + 1 == filteredLines[index].index {
                lineSection.append(filteredLines[index])
            } else if !lineSection.isEmpty {
                blankLinesSections.append(lineSection)
                lineSection.removeAll()
            }
            previousIndex = index
        }
        if !lineSection.isEmpty {
            blankLinesSections.append(lineSection)
        }

        // filtering out violations in comments and strings
        let stringAndComments = Set(SyntaxKind.commentAndStringKinds())
        let syntaxMap = file.syntaxMap
        var result = [(lastLine: Line, linesToRemove: Int)]()
        for eachSection in blankLinesSections {
            guard let lastLine = eachSection.last else { continue }
            let kindInSection = syntaxMap.tokensIn(lastLine.byteRange)
                                        .flatMap { SyntaxKind(rawValue: $0.type) }
            if stringAndComments.isDisjointWith(kindInSection) {
                result.append((lastLine, eachSection.count))
            }
        }

        return result

    }

    public func correctFile(file: File) -> [Correction] {
        let linesSections = validate(file)
        if linesSections.isEmpty { return [] }

        var indexOfLinesToDelete = [Int]()

        for eachLine in linesSections {
            let start = eachLine.lastLine.index - eachLine.linesToRemove
            indexOfLinesToDelete.appendContentsOf(start..<eachLine.lastLine.index)
        }

        var correctedLines = [String]()
        var corrections = [Correction]()
        for currentLine in file.lines {

            // Doesnt correct lines where rule is disabled
            if file.ruleEnabledViolatingRanges([currentLine.range], forRule: self).isEmpty {
                correctedLines.append(currentLine.content)
                continue
            }

            // removes lines by skipping them from correctedLines
            if Set(indexOfLinesToDelete).contains(currentLine.index) {
                let description = self.dynamicType.description
                let location = Location(file: file.path, line: currentLine.index)

                //reports every line that is being deleted
                corrections.append(Correction(ruleDescription: description, location: location))
                continue // skips line
            }

            // all lines that pass get added to final output file
            correctedLines.append(currentLine.content)
        }
        // converts lines back to file and adds trailing line
        if !corrections.isEmpty {
            file.write(correctedLines.joinWithSeparator("\n") + "\n")
            return corrections
        }
        return []

    }

}
