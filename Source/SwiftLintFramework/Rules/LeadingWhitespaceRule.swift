//
//  LeadingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LeadingWhitespaceRule: CorrectableRule, ConfigurationProviderRule, SourceKitFreeRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "leading_whitespace",
        name: "Leading Whitespace",
        description: "Files should not contain leading whitespace.",
        kind: .style,
        nonTriggeringExamples: [ "//\n" ],
        triggeringExamples: [ "\n", " //\n" ],
        corrections: ["\n //": "//"]
    )

    public func validate(file: File) -> [StyleViolation] {
        let countOfLeadingWhitespace = file.contents.countOfLeadingCharacters(in: .whitespacesAndNewlines)
        if countOfLeadingWhitespace == 0 {
            return []
        }

        let reason = "File shouldn't start with whitespace: " +
                     "currently starts with \(countOfLeadingWhitespace) whitespace characters"

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file.path, line: 1),
                               reason: reason)]
    }

    public func correct(file: File) -> [Correction] {
        let whitespaceAndNewline = CharacterSet.whitespacesAndNewlines
        let spaceCount = file.contents.countOfLeadingCharacters(in: whitespaceAndNewline)
        guard spaceCount > 0,
            let firstLineRange = file.lines.first?.range,
            !file.ruleEnabled(violatingRanges: [firstLineRange], for: self).isEmpty else {
                return []
        }

        let indexEnd = file.contents.index(
            file.contents.startIndex,
            offsetBy: spaceCount,
            limitedBy: file.contents.endIndex) ?? file.contents.endIndex
        file.write(String(file.contents[indexEnd...]))
        let location = Location(file: file.path, line: max(file.lines.count, 1))
        return [Correction(ruleDescription: type(of: self).description, location: location)]
    }
}
