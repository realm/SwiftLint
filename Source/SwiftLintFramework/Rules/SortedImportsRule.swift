//
//  SortedImportsRule.swift
//  SwiftLint
//
//  Created by Scott Berrevoets on 12/15/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private extension Line {
    var contentRange: NSRange {
        return NSRange(location: range.location, length: content.characters.count)
    }

    // `Line` in this rule always contains word import
    // This method returns contents of line that are after import
    private func afterImport() -> String {
        guard let range = content.range(of: "import ") else { return "" }
        return String(content.characters.suffix(from: range.upperBound))
    }

    // Case insensitive comparission of contents of the line
    // after the word `import`
    static func <= (lhs: Line, rhs: Line) -> Bool {
        return lhs.afterImport().lowercased() <= rhs.afterImport().lowercased()
    }
}

private extension Array where Element == Line {
    // Groups lines, so that lines that are one after the other
    // will end up in same group.
    func grouped() -> [[Line]] {
        return self.reduce([[Line]]()) { result, line in
            if let last = result.last?.last {
                var copy = result
                if last.index == line.index - 1 {
                    copy[copy.count - 1].append(line)
                } else {
                    copy.append([line])
                }
                return copy
            } else {
                return [[line]]
            }
        }
    }
}

public struct SortedImportsRule: CorrectableRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "sorted_imports",
        name: "Sorted Imports",
        description: "Imports should be sorted.",
        kind: .style,
        nonTriggeringExamples: [
            "import AAA\nimport BBB\nimport CCC\nimport DDD",
            "import Alamofire\nimport API",
            "import labc\nimport Ldef",
            "import BBB\n// comment\nimport AAA\nimport CCC"
        ],
        triggeringExamples: [
            "import AAA\nimport ZZZ\nimport ↓BBB\nimport CCC",
            "import BBB\n// comment\nimport CCC\nimport ↓AAA"
        ],
        corrections: [
            "import AAA\nimport ZZZ\nimport ↓BBB\nimport CCC": "import AAA\nimport BBB\nimport CCC\nimport ZZZ",
            "import BBB // comment\nimport ↓AAA": "import AAA\nimport BBB // comment",
            "import BBB\n// comment\nimport CCC\nimport ↓AAA": "import BBB\n// comment\nimport AAA\nimport CCC",
            "@testable import CCC\nimport AAA": "import AAA\n@testable import CCC"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let groups = self.importGroups(in: file)
        return self.violatingOffsets(in: groups).map { index -> StyleViolation in
            let location = Location(file: file, characterOffset: index)
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: location)
        }
    }

    private func importGroups(in file: File) -> [[Line]] {
        let importRanges = file.match(pattern: "import\\s+\\w+", with: [.keyword, .identifier])
        let enabledImportRanges = file.ruleEnabled(violatingRanges: importRanges, for: self)

        let contents = file.contents.bridge()
        let lines = contents.lines()
        let importLines: [Line] = enabledImportRanges.flatMap { range in
            guard let line = contents.lineAndCharacter(forCharacterOffset: range.location)?.line
                else { return nil }
            return lines[line - 1]
        }

        return importLines.grouped()
    }

    private func violatingOffsets(in groups: [[Line]]) -> [Int] {
        var violatingOffsets = [Int]()
        groups.forEach { group in
            let pairs = zip(group, group.dropFirst())
            pairs.forEach { previous, current in
                let isOrderedCorrectly = previous <= current
                if !isOrderedCorrectly {
                    violatingOffsets.append(current.range.location + 7)
                }
            }
        }
        return violatingOffsets
    }

    public func correct(file: File) -> [Correction] {
        var groups = self.importGroups(in: file)

        let corrections = self.violatingOffsets(in: groups).map { index -> Correction in
            let location = Location(file: file, characterOffset: index)
            return Correction(ruleDescription: type(of: self).description, location: location)
        }

        groups.enumerated().forEach { index, group in
            groups[index] = group.sorted { previous, current in
                previous <= current
            }
        }

        let correctedContents = NSMutableString(string: file.contents)
        groups.forEach { group in
            if let first = group.first?.contentRange {
                let result = group.map { $0.content }.joined(separator: "\n")
                let union = group.dropFirst().reduce(first, { result, line in
                    return NSUnionRange(result, line.contentRange)
                })
                correctedContents.replaceCharacters(in: union, with: result)
            }
        }
        file.write(correctedContents.bridge())

        return corrections
    }
}
