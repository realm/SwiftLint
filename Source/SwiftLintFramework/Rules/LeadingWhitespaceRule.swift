//
//  LeadingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension String {
    private func countOfLeadingCharactersInSet(characterSet: NSCharacterSet) -> Int {
        var count = 0
        for char in utf16 {
            if !characterSet.characterIsMember(char) {
                break
            }
            count += 1
        }
        return count
    }
    private func leadingNewlineAndWhiteSpaceCount() -> Int? {
        return countOfLeadingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}

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

    public func validateFile(file: File) -> [StyleViolation] {
        let countOfLeadingWhitespace = file.contents.countOfLeadingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        if countOfLeadingWhitespace == 0 {
            return []
        }
        return [StyleViolation(ruleDescription: self.dynamicType.description,
            severity: configuration.severity,
            location: Location(file: file.path, line: 1),
            reason: "File shouldn't start with whitespace: " +
            "currently starts with \(countOfLeadingWhitespace) whitespace characters")]
    }

    public func correctFile(file: File) -> [Correction] {
        guard let spaceCount = file.contents.leadingNewlineAndWhiteSpaceCount()
            where spaceCount != 0  else {
            return []
        }
        let region = file.regions().filter {
            $0.contains(Location(file: file.path, line: max(file.lines.count, 1)))
            }.first
        if region?.isRuleDisabled(self) == true {
            return []
        }
        file.write(file.contents.substringFromIndex(
                file.contents.startIndex.advancedBy(spaceCount)))

        let location = Location(file: file.path, line: max(file.lines.count, 1))
        return [Correction(ruleDescription: self.dynamicType.description, location: location)]
    }
}
