//
//  EmptyEnumArgumentsRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 05/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct EmptyEnumArgumentsRule: ASTRule, ConfigurationProviderRule, CorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_enum_arguments",
        name: "Empty Enum Arguments",
        description: "Arguments can be omitted when matching enums with associated types if they are not used.",
        nonTriggeringExamples: [
            "switch foo {\n case .bar: break\n}",
            "switch foo {\n case .bar(let x): break\n}",
            "switch foo {\n case let .bar(x): break\n}",
            "switch (foo, bar) {\n case (_, _): break\n}"
        ],
        triggeringExamples: [
            "switch foo {\n case .bar↓(_): break\n}",
            "switch foo {\n case .bar↓(): break\n}",
            "switch foo {\n case .bar↓(_), .bar2↓(_): break\n}",
            "switch foo {\n case .bar↓() where method() > 2: break\n}"
        ],
        corrections: [
            "switch foo {\n case .bar↓(_): break\n}":
                "switch foo {\n case .bar: break\n}",
            "switch foo {\n case .bar↓(): break\n}":
                "switch foo {\n case .bar: break\n}",
            "switch foo {\n case .bar↓(_), .bar2↓(_): break\n}":
                "switch foo {\n case .bar, .bar2: break\n}",
            "switch foo {\n case .bar↓() where method() > 2: break\n}":
                "switch foo {\n case .bar where method() > 2: break\n}"
        ]
    )

    public func validate(file: File, kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(in file: File, kind: StatementKind,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard kind == .case else {
            return []
        }

        let contents = file.contents.bridge()

        return dictionary.elements.flatMap { subDictionary -> [NSRange] in
            guard subDictionary.kind == "source.lang.swift.structure.elem.pattern",
                let offset = subDictionary.offset,
                let length = subDictionary.length,
                let caseRange = contents.byteRangeToNSRange(start: offset, length: length) else {
                    return []
            }

            return file.match(pattern: "\\([,\\s_]*\\)", range: caseRange).flatMap { arg in
                let (range, kinds) = arg
                guard Set(kinds).isSubset(of: [.keyword]),
                    case let byteRange = NSRange(location: offset, length: length),
                    Set(file.syntaxMap.kinds(inByteRange: byteRange)) != [.keyword] else {
                        return nil
                }

                // avoid matches after `where` keyworkd
                if let whereMatch = file.match(pattern: "where", with: [.keyword], range: caseRange).first,
                    whereMatch.location < range.location {
                    return nil
                }

                return range
            }
        }
    }

    private func violationRanges(in file: File, dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        return dictionary.substructure.flatMap { subDict -> [NSRange] in
            guard let kindString = subDict.kind,
                let kind = StatementKind(rawValue: kindString) else {
                    return []
            }
            return violationRanges(in: file, dictionary: subDict) +
                violationRanges(in: file, kind: kind, dictionary: subDict)
        }
    }

    private func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(in: file, dictionary: file.structure.dictionary).sorted { lhs, rhs in
            lhs.location < rhs.location
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: "")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }
}
