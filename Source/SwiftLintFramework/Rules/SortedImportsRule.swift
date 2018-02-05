//
//  SortedImportsRule.swift
//  SwiftLint
//
//  Created by Scott Berrevoets on 12/15/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension Line {
    fileprivate var contentRange: NSRange {
        return NSRange(location: range.location, length: content.bridge().length)
    }

    // `Line` in this rule always contains word import
    // This method returns contents of line that are after import
    private func importModule() -> Substring {
        return content[importModuleRange()]
    }

    fileprivate func importModuleRange() -> Range<String.Index> {
        let rangeOfImport = content.range(of: "import")
        precondition(rangeOfImport != nil)
        let moduleStart = content.rangeOfCharacter(from: CharacterSet.whitespaces.inverted, options: [],
                                                   range: rangeOfImport!.upperBound..<content.endIndex)
        return moduleStart!.lowerBound..<content.endIndex
    }

    // Case insensitive comparison of contents of the line
    // after the word `import`
    fileprivate static func <= (lhs: Line, rhs: Line) -> Bool {
        return lhs.importModule().lowercased() <= rhs.importModule().lowercased()
    }
}

private extension Sequence where Element == Line {
    // Groups lines, so that lines that are one after the other
    // will end up in same group.
    func grouped() -> [[Line]] {
        return reduce([[]]) { result, line in
            guard let last = result.last?.last else {
                return [[line]]
            }
            var copy = result
            if last.index == line.index - 1 {
                copy[copy.count - 1].append(line)
            } else {
                copy.append([line])
            }
            return copy
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
            "import BBB\n// comment\nimport AAA\nimport CCC",
            "@testable import AAA\nimport   CCC",
            "import AAA\n@testable import   CCC",
            """
            import EEE.A
            import FFF.B
            #if os(Linux)
            import DDD.A
            import EEE.B
            #else
            import CCC
            import DDD.B
            #endif
            import AAA
            import BBB
            """
        ],
        triggeringExamples: [
            "import AAA\nimport ZZZ\nimport ↓BBB\nimport CCC",
            "import DDD\n// comment\nimport CCC\nimport ↓AAA",
            "@testable import CCC\nimport   ↓AAA",
            "import CCC\n@testable import   ↓AAA",
            """
            import FFF.B
            import ↓EEE.A
            #if os(Linux)
            import DDD.A
            import EEE.B
            #else
            import DDD.B
            import ↓CCC
            #endif
            import AAA
            import BBB
            """
        ],
        corrections: [
            "import AAA\nimport ZZZ\nimport ↓BBB\nimport CCC": "import AAA\nimport BBB\nimport CCC\nimport ZZZ",
            "import BBB // comment\nimport ↓AAA": "import AAA\nimport BBB // comment",
            "import BBB\n// comment\nimport CCC\nimport ↓AAA": "import BBB\n// comment\nimport AAA\nimport CCC",
            "@testable import CCC\nimport  ↓AAA": "import  AAA\n@testable import CCC",
            "import CCC\n@testable import  ↓AAA": "@testable import  AAA\nimport CCC",
            """
            import FFF.B
            import ↓EEE.A
            #if os(Linux)
            import DDD.A
            import EEE.B
            #else
            import DDD.B
            import ↓CCC
            #endif
            import AAA
            import BBB
            """:
            """
            import EEE.A
            import FFF.B
            #if os(Linux)
            import DDD.A
            import EEE.B
            #else
            import CCC
            import DDD.B
            #endif
            import AAA
            import BBB
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let groups = importGroups(in: file, filterEnabled: false)
        return violatingOffsets(inGroups: groups).map { index -> StyleViolation in
            let location = Location(file: file, characterOffset: index)
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: location)
        }
    }

    private func importGroups(in file: File, filterEnabled: Bool) -> [[Line]] {
        var importRanges = file.match(pattern: "import\\s+\\w+", with: [.keyword, .identifier])
        if filterEnabled {
            importRanges = file.ruleEnabled(violatingRanges: importRanges, for: self)
        }

        let contents = file.contents.bridge()
        let lines = contents.lines()
        let importLines: [Line] = importRanges.compactMap { range in
            guard let line = contents.lineAndCharacter(forCharacterOffset: range.location)?.line
                else { return nil }
            return lines[line - 1]
        }

        return importLines.grouped()
    }

    private func violatingOffsets(inGroups groups: [[Line]]) -> [Int] {
        return groups.flatMap { group in
            return zip(group, group.dropFirst()).reduce([]) { violatingOffsets, groupPair in
                let (previous, current) = groupPair
                let isOrderedCorrectly = previous <= current
                if isOrderedCorrectly {
                    return violatingOffsets
                }
                let distance = current.content.distance(from: current.content.startIndex,
                                                        to: current.importModuleRange().lowerBound)
                return violatingOffsets + [current.range.location + distance]
            }
        }
    }

    public func correct(file: File) -> [Correction] {
        let groups = importGroups(in: file, filterEnabled: true)

        let corrections = violatingOffsets(inGroups: groups).map { characterOffset -> Correction in
            let location = Location(file: file, characterOffset: characterOffset)
            return Correction(ruleDescription: type(of: self).description, location: location)
        }

        guard !corrections.isEmpty else {
            return []
        }

        let correctedContents = NSMutableString(string: file.contents)
        for group in groups.map({ $0.sorted(by: <=) }) {
            guard let first = group.first?.contentRange else {
                continue
            }
            let result = group.map { $0.content }.joined(separator: "\n")
            let union = group.dropFirst().reduce(first) { result, line in
                return NSUnionRange(result, line.contentRange)
            }
            correctedContents.replaceCharacters(in: union, with: result)
        }
        file.write(correctedContents.bridge())

        return corrections
    }
}
