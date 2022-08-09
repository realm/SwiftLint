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
            Example("CGPoint(x: 10, y: 10)"),
            Example("CGPoint(x: xValue, y: yValue)"),
            Example("CGSize(width: 10, height: 10)"),
            Example("CGSize(width: aWidth, height: aHeight)"),
            Example("CGRect(x: 0, y: 0, width: 10, height: 10)"),
            Example("CGRect(x: xVal, y: yVal, width: aWidth, height: aHeight)"),
            Example("CGVector(dx: 10, dy: 10)"),
            Example("CGVector(dx: deltaX, dy: deltaY)"),
            Example("NSPoint(x: 10, y: 10)"),
            Example("NSPoint(x: xValue, y: yValue)"),
            Example("NSSize(width: 10, height: 10)"),
            Example("NSSize(width: aWidth, height: aHeight)"),
            Example("NSRect(x: 0, y: 0, width: 10, height: 10)"),
            Example("NSRect(x: xVal, y: yVal, width: aWidth, height: aHeight)"),
            Example("NSRange(location: 10, length: 1)"),
            Example("NSRange(location: loc, length: len)"),
            Example("UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)"),
            Example("UIEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)"),
            Example("NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)"),
            Example("NSEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)"),
            Example("UIOffset(horizontal: 0, vertical: 10)"),
            Example("UIOffset(horizontal: horizontal, vertical: vertical)")
        ],
        triggeringExamples: [
            Example("↓CGPointMake(10, 10)"),
            Example("↓CGPointMake(xVal, yVal)"),
            Example("↓CGPointMake(calculateX(), 10)\n"),
            Example("↓CGSizeMake(10, 10)"),
            Example("↓CGSizeMake(aWidth, aHeight)"),
            Example("↓CGRectMake(0, 0, 10, 10)"),
            Example("↓CGRectMake(xVal, yVal, width, height)"),
            Example("↓CGVectorMake(10, 10)"),
            Example("↓CGVectorMake(deltaX, deltaY)"),
            Example("↓NSMakePoint(10, 10)"),
            Example("↓NSMakePoint(xVal, yVal)"),
            Example("↓NSMakeSize(10, 10)"),
            Example("↓NSMakeSize(aWidth, aHeight)"),
            Example("↓NSMakeRect(0, 0, 10, 10)"),
            Example("↓NSMakeRect(xVal, yVal, width, height)"),
            Example("↓NSMakeRange(10, 1)"),
            Example("↓NSMakeRange(loc, len)"),
            Example("↓UIEdgeInsetsMake(0, 0, 10, 10)"),
            Example("↓UIEdgeInsetsMake(top, left, bottom, right)"),
            Example("↓NSEdgeInsetsMake(0, 0, 10, 10)"),
            Example("↓NSEdgeInsetsMake(top, left, bottom, right)"),
            Example("↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)"),
            Example("↓UIOffsetMake(0, 10)"),
            Example("↓UIOffsetMake(horizontal, vertical)")
        ],
        corrections: [
            Example("↓CGPointMake(10,  10   )\n"): Example("CGPoint(x: 10, y: 10)\n"),
            Example("↓CGPointMake(xPos,  yPos   )\n"): Example("CGPoint(x: xPos, y: yPos)\n"),
            Example("↓CGSizeMake(10, 10)\n"): Example("CGSize(width: 10, height: 10)\n"),
            Example("↓CGSizeMake( aWidth, aHeight )\n"): Example("CGSize(width: aWidth, height: aHeight)\n"),
            Example("↓CGRectMake(0, 0, 10, 10)\n"): Example("CGRect(x: 0, y: 0, width: 10, height: 10)\n"),
            Example("↓CGRectMake(xPos, yPos , width, height)\n"):
                Example("CGRect(x: xPos, y: yPos, width: width, height: height)\n"),
            Example("↓CGVectorMake(10, 10)\n"): Example("CGVector(dx: 10, dy: 10)\n"),
            Example("↓CGVectorMake(deltaX, deltaY)\n"): Example("CGVector(dx: deltaX, dy: deltaY)\n"),
            Example("↓NSMakePoint(10,  10   )\n"): Example("NSPoint(x: 10, y: 10)\n"),
            Example("↓NSMakePoint(xPos,  yPos   )\n"): Example("NSPoint(x: xPos, y: yPos)\n"),
            Example("↓NSMakeSize(10, 10)\n"): Example("NSSize(width: 10, height: 10)\n"),
            Example("↓NSMakeSize( aWidth, aHeight )\n"): Example("NSSize(width: aWidth, height: aHeight)\n"),
            Example("↓NSMakeRect(0, 0, 10, 10)\n"): Example("NSRect(x: 0, y: 0, width: 10, height: 10)\n"),
            Example("↓NSMakeRect(xPos, yPos , width, height)\n"):
                Example("NSRect(x: xPos, y: yPos, width: width, height: height)\n"),
            Example("↓NSMakeRange(10, 1)\n"): Example("NSRange(location: 10, length: 1)\n"),
            Example("↓NSMakeRange(loc, len)\n"): Example("NSRange(location: loc, length: len)\n"),
            Example("↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)\n"):
                Example("CGVector(dx: 10, dy: 10)\nNSRange(location: 10, length: 1)\n"),
            Example("↓CGVectorMake(dx, dy)\n↓NSMakeRange(loc, len)\n"):
                Example("CGVector(dx: dx, dy: dy)\nNSRange(location: loc, length: len)\n"),
            Example("↓UIEdgeInsetsMake(0, 0, 10, 10)\n"):
                Example("UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)\n"),
            Example("↓UIEdgeInsetsMake(top, left, bottom, right)\n"):
                Example("UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)\n"),
            Example("↓NSEdgeInsetsMake(0, 0, 10, 10)\n"):
                Example("NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)\n"),
            Example("↓NSEdgeInsetsMake(top, left, bottom, right)\n"):
                Example("NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)\n"),
            Example("↓NSMakeRange(0, attributedString.length)\n"):
                Example("NSRange(location: 0, length: attributedString.length)\n"),
            Example("↓CGPointMake(calculateX(), 10)\n"): Example("CGPoint(x: calculateX(), y: 10)\n"),
            Example("↓UIOffsetMake(0, 10)\n"): Example("UIOffset(horizontal: 0, vertical: 10)\n"),
            Example("↓UIOffsetMake(horizontal, vertical)\n"):
                Example("UIOffset(horizontal: horizontal, vertical: vertical)\n")
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

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard containsViolation(kind: kind, dictionary: dictionary),
            let offset = dictionary.offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func violations(in file: SwiftLintFile, kind: SwiftExpressionKind,
                            dictionary: SourceKittenDictionary) -> [SourceKittenDictionary] {
        guard containsViolation(kind: kind, dictionary: dictionary) else {
            return []
        }

        return [dictionary]
    }

    private func containsViolation(kind: SwiftExpressionKind,
                                   dictionary: SourceKittenDictionary) -> Bool {
        guard kind == .call,
            let name = dictionary.name,
            dictionary.offset != nil,
            let expectedArguments = Self.constructorsToArguments[name],
            dictionary.enclosedArguments.count == expectedArguments.count else {
                return false
        }

        return true
    }

    private func violations(in file: SwiftLintFile,
                            dictionary: SourceKittenDictionary) -> [SourceKittenDictionary] {
        return dictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.expressionKind else { return nil }
            return violations(in: file, kind: kind, dictionary: subDict)
        }
    }

    private func violations(in file: SwiftLintFile) -> [SourceKittenDictionary] {
        return violations(in: file, dictionary: file.structureDictionary).sorted { lhs, rhs in
            (lhs.offset ?? 0) < (rhs.offset ?? 0)
        }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        let violatingDictionaries = violations(in: file)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for dictionary in violatingDictionaries.reversed() {
            guard let byteRange = dictionary.byteRange,
                let range = file.stringView.byteRangeToNSRange(byteRange),
                let name = dictionary.name,
                let correctedName = Self.constructorsToCorrectedNames[name],
                file.ruleEnabled(violatingRanges: [range], for: self) == [range],
                case let arguments = argumentsContents(file: file, arguments: dictionary.enclosedArguments),
                let expectedArguments = Self.constructorsToArguments[name],
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
            Correction(ruleDescription: Self.description,
                       location: Location(file: file, characterOffset: $0))
        }

        file.write(correctedContents)

        return corrections
    }

    private func argumentsContents(file: SwiftLintFile, arguments: [SourceKittenDictionary]) -> [String] {
        let contents = file.stringView
        return arguments.compactMap { argument -> String? in
            guard argument.name == nil, let byteRange = argument.byteRange else {
                return nil
            }

            return contents.substringWithByteRange(byteRange)
        }
    }
}
