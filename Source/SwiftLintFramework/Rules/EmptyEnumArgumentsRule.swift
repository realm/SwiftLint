//
//  EmptyEnumArgumentsRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 05/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private func wrapInSwitch(variable: String = "foo", _ str: String) -> String {
    return  "switch \(variable) {\n" +
            "    \(str): break\n" +
            "}"
}

public struct EmptyEnumArgumentsRule: ASTRule, ConfigurationProviderRule, CorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_enum_arguments",
        name: "Empty Enum Arguments",
        description: "Arguments can be omitted when matching enums with associated types if they are not used.",
        kind: .style,
        nonTriggeringExamples: [
            wrapInSwitch("case .bar"),
            wrapInSwitch("case .bar(let x)"),
            wrapInSwitch("case let .bar(x)"),
            wrapInSwitch(variable: "(foo, bar)", "case (_, _)"),
            wrapInSwitch("case \"bar\".uppercased()"),
            wrapInSwitch(variable: "(foo, bar)", "case (_, _) where !something")
        ],
        triggeringExamples: [
            wrapInSwitch("case .bar↓(_)"),
            wrapInSwitch("case .bar↓()"),
            wrapInSwitch("case .bar↓(_), .bar2↓(_)"),
            wrapInSwitch("case .bar↓() where method() > 2")
        ],
        corrections: [
            wrapInSwitch("case .bar↓(_)"): wrapInSwitch("case .bar"),
            wrapInSwitch("case .bar↓()"): wrapInSwitch("case .bar"),
            wrapInSwitch("case .bar↓(_), .bar2↓(_)"): wrapInSwitch("case .bar, .bar2"),
            wrapInSwitch("case .bar↓() where method() > 2"): wrapInSwitch("case .bar where method() > 2")
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

        let callsRanges = dictionary.substructure.flatMap { dict -> NSRange? in
            guard dict.kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .call,
                let offset = dict.offset,
                let length = dict.length,
                let range = contents.byteRangeToNSRange(start: offset, length: length) else {
                    return nil
            }

            return range
        }

        return dictionary.elements.flatMap { subDictionary -> [NSRange] in
            guard subDictionary.kind == "source.lang.swift.structure.elem.pattern",
                let offset = subDictionary.offset,
                let length = subDictionary.length,
                let caseRange = contents.byteRangeToNSRange(start: offset, length: length) else {
                    return []
            }

            return file.match(pattern: "\\([,\\s_]*\\)", range: caseRange).flatMap { range, kinds in
                guard Set(kinds).isSubset(of: [.keyword]),
                    case let byteRange = NSRange(location: offset, length: length),
                    Set(file.syntaxMap.kinds(inByteRange: byteRange)) != [.keyword] else {
                        return nil
                }

                // avoid matches after `where` keyworkd
                if let whereRange = file.match(pattern: "where", with: [.keyword], range: caseRange).first {
                    if whereRange.location < range.location {
                        return nil
                    }

                    // avoid matches in "(_, _) where"
                    if let whereByteRange = contents.NSRangeToByteRange(start: whereRange.location,
                                                                        length: whereRange.length),
                        case let length = whereByteRange.location - offset,
                        case let byteRange = NSRange(location: offset, length: length),
                        Set(file.syntaxMap.kinds(inByteRange: byteRange)) == [.keyword] {
                        return nil
                    }
                }

                if callsRanges.contains(where: range.intersects) {
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
