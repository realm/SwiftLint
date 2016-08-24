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
                                      ConfigurationProviderRule, OptInRule {

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
        ] // End of line autocorrections are handeled by Trailing Newline Rule.
    )

    public func validateFile(file: File) -> [StyleViolation] {

        let linesSections = validate(file)
        if linesSections.isEmpty { return [] }

        var violations = [StyleViolation]()
        for (eachLastLine, eachSectionCount) in linesSections {

            // Skips violation for areas where the rule is disabled
            let region = file.regions().filter {
                $0.contains(Location(file: file.path, line: eachLastLine.index, character: 0))
            }.first
            if region?.isRuleDisabled(self) == true {
                continue
            }

            let violation = StyleViolation(ruleDescription: self.dynamicType.description,
                                           severity: configuration.severity,
                                           location: Location(file: file.path,
                                            line: eachLastLine.index ),
                                           reason: descriptionReason
                                            + " Currently \(eachSectionCount + 1)." )
            violations.append(violation)
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

        // matching all accurrences of /* */
        let matchMultilineComments = "/\\*(.|[\\r\\n])*?\\*/"
        let comments = file.matchPattern(matchMultilineComments)

        var result = [(lastLine: Line, linesToRemove: Int)]()
        for eachSection in blankLinesSections {
            guard let lastLine = eachSection.last else { continue }

            // filtering out violations within a multiple comment block
            let isSectionInComment = !comments.filter {
                (eachRange, _ ) in eachRange.intersectsRange(lastLine.range)
            }.isEmpty

            if isSectionInComment {
                continue  // skipping the lines found in multiline comment
            } else {
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
        let fileRegions = file.regions()

        forLoopCounter: for currentLine in file.lines {

            // Doesnt correct lines where rule is disabled
            let region = fileRegions.filter {
                $0.contains(Location(file: file.path, line: currentLine.index, character: 0))
            }.first
            if region?.isRuleDisabled(self) == true {
                correctedLines.append(currentLine.content)
                continue forLoopCounter
            }

            // by not incling lines in correctedLines, it removes them
            if Set(indexOfLinesToDelete).contains(currentLine.index) {
                let description = self.dynamicType.description
                let location = Location(file: file.path, line: currentLine.index)

                //reports every line that is being deleted
                corrections.append(Correction(ruleDescription: description, location: location))
                continue forLoopCounter
            }

            // all lines that pass get added to final output file
            correctedLines.append(currentLine.content)
        }
        // converts lines back to file, add trailing line
        if !corrections.isEmpty {
            file.write(correctedLines.joinWithSeparator("\n") + "\n")
            return corrections
        }
        return []

    }

}
