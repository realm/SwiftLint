//
//  ClosureSpacingRule.swift
//  SwiftLint
//
//  Created by J. Cheyo Jimenez on 2016-08-26.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ClosureSpacingRule: Rule, ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_spacing",
        name: "Closure Spacing",
        description: "Closure expressions should have a single space inside each brace.",
        nonTriggeringExamples: [
            "[].map ({ $0.description })",
            "[].filter { $0.contains(location) }"
        ],
        triggeringExamples: [
            "[].filter({$0.contains(location)})",
            "[].map({$0})"
        ]
    )

    // this helps cut down the time to search true a file by
    // skipping lines that do not have at least one { and one } brace
    func lineContainsBracesIn(range: NSRange, content: NSString) -> NSRange? {
        let start = content.rangeOfString("{", options: [.LiteralSearch], range: range)
        guard start.length != 0 else { return nil }
        let end = content.rangeOfString("}",
                             options: [.LiteralSearch, .BackwardsSearch], range: range)
        guard end.length != 0 else { return nil }
        guard start.location < end.location else { return nil }
        return NSRange(location: start.location,
                                length: end.location - start.location + 1)
    }

    // returns ranges of braces { or } in the same line
    func validBraces(file: File) -> [NSRange] {
        let nsstring = (file.contents as NSString)
        let bracePattern = regex("\\{|\\}")
        let linesTokens = file.syntaxTokensByLines
        let kindsToExclude = SyntaxKind.commentAndStringKinds().map { $0.rawValue }

        // find all lines and accurences of open { and closed } braces
        var linesWithBraces = [[NSRange]]()
        for eachLine in file.lines {
            guard let nsrange  = lineContainsBracesIn(eachLine.range, content: nsstring)
                else { continue }

            let braces = bracePattern.matchesInString(file.contents, options: [],
                                                        range: nsrange).map { $0.range }
            // filter out braces in comments and strings
            let tokens = linesTokens[eachLine.index].filter { kindsToExclude.contains($0.type) }
            let tokenRanges = tokens.flatMap {
                          file.contents.byteRangeToNSRange(start: $0.offset, length: $0.length) }
            linesWithBraces.append(braces.filter { !$0.intersectsRanges(tokenRanges) })
        }
        return linesWithBraces.flatMap { $0 }
    }

    public func validateFile(file: File) -> [StyleViolation] {

        // match open braces to corresponding closing braces
        func matchBraces(validBraceLocations: [NSRange]) -> [NSRange] {
            if validBraceLocations.isEmpty { return [] }
            var validBraces = validBraceLocations
            var ranges = [NSRange]()
            var bracesAsString = validBraces.map {
                file.contents.substring($0.location, length: $0.length) }.joinWithSeparator("")
            while let foundRange = bracesAsString.rangeOfString("{}") {
                let startIndex = bracesAsString.startIndex.distanceTo(foundRange.startIndex)
                let location = validBraces[startIndex].location
                let length = validBraces[startIndex + 1 ].location + 1 - location
                ranges.append(NSRange(location:location, length: length))
                bracesAsString.replaceRange(foundRange, with: "")
                validBraces.removeRange(startIndex...startIndex  + 1)
            }
            return ranges
        }

        // matching ranges of {}
        let matchedUpBraces = matchBraces(validBraces(file))

        var violationRanges = matchedUpBraces.filter {
            //removes enclosing brances to just content
            let content = file.contents.substring($0.location + 1, length: $0.length - 2)
            if content.isEmpty { return false } // case when {} is not a closure
            let cleaned = content.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
            return content != " " + cleaned + " "
        }

        //filter out ranges where rule is disabled
        violationRanges = file.ruleEnabledViolatingRanges(violationRanges, forRule: self)

        return violationRanges.flatMap { StyleViolation(
            ruleDescription: self.dynamicType.description,
            severity: configuration.severity,
            location: Location(file: file, characterOffset: $0.location)
            )}
    }
}
