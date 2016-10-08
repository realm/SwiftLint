//
//  LeadingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LeadingWhitespaceRule: CorrectableRule, ConfigurationProviderRule, SourceKitFreeRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "leading_whitespace",
        name: "Leading Whitespace",
        description: "Files should not contain leading whitespace.",
        nonTriggeringExamples: [ "//\n" ],
        triggeringExamples: [ "\n", " //\n" ],
        corrections: ["\n": ""]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let countOfLeadingWhitespace = file.contents.countOfLeadingCharactersInSet(
            CharacterSet.whitespacesAndNewlines
        )
        if countOfLeadingWhitespace == 0 {
            return []
        }
        return [StyleViolation(ruleDescription: type(of: self).description,
            severity: configuration.severity,
            location: Location(file: file.path, line: 1),
            reason: "File shouldn't start with whitespace: " +
            "currently starts with \(countOfLeadingWhitespace) whitespace characters")]
    }

    public func correctFile(_ file: File) -> [Correction] {
        let whitespaceAndNewline = CharacterSet.whitespacesAndNewlines
        let spaceCount = file.contents.countOfLeadingCharactersInSet(whitespaceAndNewline)
        if spaceCount == 0 {
            return []
        }
        let region = file.regions().filter {
            $0.contains(Location(file: file.path, line: max(file.lines.count, 1)))
        }.first
        if region?.isRuleDisabled(self) == true {
            return []
        }
        let indexEnd = file.contents.index(
            file.contents.startIndex,
            offsetBy:spaceCount,
            limitedBy: file.contents.endIndex) ?? file.contents.endIndex
        file.write(file.contents.substring(from: indexEnd))
        let location = Location(file: file.path, line: max(file.lines.count, 1))
        return [Correction(ruleDescription: type(of: self).description, location: location)]
    }
}
