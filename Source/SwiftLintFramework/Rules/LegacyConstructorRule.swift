//
//  LegacyConstructorRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 29/11/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LegacyConstructorRule: ASTRule, CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_constructor",
        name: "Legacy Constructor",
        description: "Swift constructors are preferred over legacy convenience functions.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "CGPoint(x: 10, y: 10)",
            "CGPoint(x: xValue, y: yValue)",
            "CGSize(width: 10, height: 10)",
            "CGSize(width: aWidth, height: aHeight)",
            "CGRect(x: 0, y: 0, width: 10, height: 10)",
            "CGRect(x: xVal, y: yVal, width: aWidth, height: aHeight)",
            "CGVector(dx: 10, dy: 10)",
            "CGVector(dx: deltaX, dy: deltaY)",
            "NSPoint(x: 10, y: 10)",
            "NSPoint(x: xValue, y: yValue)",
            "NSSize(width: 10, height: 10)",
            "NSSize(width: aWidth, height: aHeight)",
            "NSRect(x: 0, y: 0, width: 10, height: 10)",
            "NSRect(x: xVal, y: yVal, width: aWidth, height: aHeight)",
            "NSRange(location: 10, length: 1)",
            "NSRange(location: loc, length: len)",
            "UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
            "UIEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)",
            "NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)",
            "NSEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)",
            "UIOffset(horizontal: 0, vertical: 10)",
            "UIOffset(horizontal: horizontal, vertical: vertical)"
        ],
        triggeringExamples: [
            "↓CGPointMake(10, 10)",
            "↓CGPointMake(xVal, yVal)",
            "↓CGPointMake(calculateX(), 10)\n",
            "↓CGSizeMake(10, 10)",
            "↓CGSizeMake(aWidth, aHeight)",
            "↓CGRectMake(0, 0, 10, 10)",
            "↓CGRectMake(xVal, yVal, width, height)",
            "↓CGVectorMake(10, 10)",
            "↓CGVectorMake(deltaX, deltaY)",
            "↓NSMakePoint(10, 10)",
            "↓NSMakePoint(xVal, yVal)",
            "↓NSMakeSize(10, 10)",
            "↓NSMakeSize(aWidth, aHeight)",
            "↓NSMakeRect(0, 0, 10, 10)",
            "↓NSMakeRect(xVal, yVal, width, height)",
            "↓NSMakeRange(10, 1)",
            "↓NSMakeRange(loc, len)",
            "↓UIEdgeInsetsMake(0, 0, 10, 10)",
            "↓UIEdgeInsetsMake(top, left, bottom, right)",
            "↓NSEdgeInsetsMake(0, 0, 10, 10)",
            "↓NSEdgeInsetsMake(top, left, bottom, right)",
            "↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)",
            "↓UIOffsetMake(0, 10)",
            "↓UIOffsetMake(horizontal, vertical)"
        ],
        corrections: [
            "↓CGPointMake(10,  10   )\n": "CGPoint(x: 10, y: 10)\n",
            "↓CGPointMake(xPos,  yPos   )\n": "CGPoint(x: xPos, y: yPos)\n",
            "↓CGSizeMake(10, 10)\n": "CGSize(width: 10, height: 10)\n",
            "↓CGSizeMake( aWidth, aHeight )\n": "CGSize(width: aWidth, height: aHeight)\n",
            "↓CGRectMake(0, 0, 10, 10)\n": "CGRect(x: 0, y: 0, width: 10, height: 10)\n",
            "↓CGRectMake(xPos, yPos , width, height)\n":
            "CGRect(x: xPos, y: yPos, width: width, height: height)\n",
            "↓CGVectorMake(10, 10)\n": "CGVector(dx: 10, dy: 10)\n",
            "↓CGVectorMake(deltaX, deltaY)\n": "CGVector(dx: deltaX, dy: deltaY)\n",
            "↓NSMakePoint(10,  10   )\n": "NSPoint(x: 10, y: 10)\n",
            "↓NSMakePoint(xPos,  yPos   )\n": "NSPoint(x: xPos, y: yPos)\n",
            "↓NSMakeSize(10, 10)\n": "NSSize(width: 10, height: 10)\n",
            "↓NSMakeSize( aWidth, aHeight )\n": "NSSize(width: aWidth, height: aHeight)\n",
            "↓NSMakeRect(0, 0, 10, 10)\n": "NSRect(x: 0, y: 0, width: 10, height: 10)\n",
            "↓NSMakeRect(xPos, yPos , width, height)\n":
            "NSRect(x: xPos, y: yPos, width: width, height: height)\n",
            "↓NSMakeRange(10, 1)\n": "NSRange(location: 10, length: 1)\n",
            "↓NSMakeRange(loc, len)\n": "NSRange(location: loc, length: len)\n",
            "↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)\n": "CGVector(dx: 10, dy: 10)\n" +
                "NSRange(location: 10, length: 1)\n",
            "↓CGVectorMake(dx, dy)\n↓NSMakeRange(loc, len)\n": "CGVector(dx: dx, dy: dy)\n" +
            "NSRange(location: loc, length: len)\n",
            "↓UIEdgeInsetsMake(0, 0, 10, 10)\n":
            "UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)\n",
            "↓UIEdgeInsetsMake(top, left, bottom, right)\n":
            "UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)\n",
            "↓NSEdgeInsetsMake(0, 0, 10, 10)\n":
            "NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)\n",
            "↓NSEdgeInsetsMake(top, left, bottom, right)\n":
            "NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)\n",
            "↓NSMakeRange(0, attributedString.length)\n":
            "NSRange(location: 0, length: attributedString.length)\n",
            "↓CGPointMake(calculateX(), 10)\n": "CGPoint(x: calculateX(), y: 10)\n",
            "↓UIOffsetMake(0, 10)\n": "UIOffset(horizontal: 0, vertical: 10)\n",
            "↓UIOffsetMake(horizontal, vertical)\n":
            "UIOffset(horizontal: horizontal, vertical: vertical)\n"
        ]
    )

    private static let constructorsToArguments = ["CGRectMake": ["x", "y", "width", "height"],
                                                  "CGPointMake": ["x", "y"],
                                                  "CGSizeMake": ["width", "height"],
                                                  "CGVectorMake": ["dx", "dy"],
                                                  "NSMakePoint": ["x", "y"],
                                                  "NSMakeSize": ["width", "height"],
                                                  "NSMakeRect": ["x", "y", "width", "height"],
                                                  "NSMakeRange": ["location", "length"],
                                                  "UIEdgeInsetsMake": ["top", "left", "bottom", "right"],
                                                  "NSEdgeInsetsMake": ["top", "left", "bottom", "right"],
                                                  "UIOffsetMake": ["horizontal", "vertical"]]

    private static let constructorsToCorrectedNames = ["CGRectMake": "CGRect",
                                                       "CGPointMake": "CGPoint",
                                                       "CGSizeMake": "CGSize",
                                                       "CGVectorMake": "CGVector",
                                                       "NSMakePoint": "NSPoint",
                                                       "NSMakeSize": "NSSize",
                                                       "NSMakeRect": "NSRect",
                                                       "NSMakeRange": "NSRange",
                                                       "UIEdgeInsetsMake": "UIEdgeInsets",
                                                       "NSEdgeInsetsMake": "NSEdgeInsets",
                                                       "UIOffsetMake": "UIOffset"]

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard containsViolation(kind: kind, dictionary: dictionary),
            let offset = dictionary.offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func violations(in file: File, kind: SwiftExpressionKind,
                            dictionary: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]] {
        guard containsViolation(kind: kind, dictionary: dictionary) else {
            return []
        }

        return [dictionary]
    }

    private func containsViolation(kind: SwiftExpressionKind,
                                   dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard kind == .call,
            let name = dictionary.name,
            dictionary.offset != nil,
            let expectedArguments = type(of: self).constructorsToArguments[name],
            dictionary.enclosedArguments.count == expectedArguments.count else {
                return false
        }

        return true
    }

    private func violations(in file: File,
                            dictionary: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]] {
        return dictionary.substructure.flatMap { subDict -> [[String: SourceKitRepresentable]] in
            var dictionaries = violations(in: file, dictionary: subDict)
            if let kind = subDict.kind.flatMap(SwiftExpressionKind.init(rawValue:)) {
                dictionaries += violations(in: file, kind: kind, dictionary: subDict)
            }

            return dictionaries
        }
    }

    private func violations(in file: File) -> [[String: SourceKitRepresentable]] {
        return violations(in: file, dictionary: file.structure.dictionary).sorted { lhs, rhs in
            (lhs.offset ?? 0) < (rhs.offset ?? 0)
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingDictionaries = violations(in: file)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for dictionary in violatingDictionaries.reversed() {
            guard let offset = dictionary.offset, let length = dictionary.length,
                let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length),
                let name = dictionary.name,
                let correctedName = type(of: self).constructorsToCorrectedNames[name],
                file.ruleEnabled(violatingRanges: [range], for: self) == [range],
                case let arguments = argumentsContents(file: file, arguments: dictionary.enclosedArguments),
                let expectedArguments = type(of: self).constructorsToArguments[name],
                arguments.count == expectedArguments.count else {
                    continue
            }

            if let indexRange = correctedContents.nsrangeToIndexRange(range) {
                let joinedArguments = zip(expectedArguments, arguments).map { "\($0): \($1)" }.joined(separator: ", ")
                let replacement = correctedName + "(" + joinedArguments + ")"
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: replacement)
                adjustedLocations.insert(range.location, at: 0)
            }
        }

        let corrections = adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }

        file.write(correctedContents)

        return corrections
    }

    private func argumentsContents(file: File, arguments: [[String: SourceKitRepresentable]]) -> [String] {
        let contents = file.contents.bridge()
        return arguments.compactMap { argument -> String? in
            guard argument.name == nil,
                let offset = argument.offset,
                let length = argument.length else {
                    return nil
            }

            return contents.substringWithByteRange(start: offset, length: length)
        }
    }
}
