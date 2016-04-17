//
//  TrailingNewlineRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension String {
    private func countOfTrailingCharactersInSet(characterSet: NSCharacterSet) -> Int {
        var count = 0
        for char in utf16.lazy.reverse() {
            if !characterSet.characterIsMember(char) {
                break
            }
            count += 1
        }
        return count
    }

    private func trailingNewlineCount() -> Int? {
        return countOfTrailingCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }
}

public struct TrailingNewlineRule: CorrectableRule, ConfigurationProviderRule, SourceKitFreeRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_newline",
        name: "Trailing Newline",
        description: "Files should have a single trailing newline.",
        nonTriggeringExamples: [
            "let a = 0\n"
        ],
        triggeringExamples: [
            "let a = 0",
            "let a = 0\n\n"
        ],
        corrections: [
            "let a = 0": "let a = 0\n",
            "let b = 0\n\n": "let b = 0\n",
            "let c = 0\n\n\n\n": "let c = 0\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        if file.contents.trailingNewlineCount() == 1 {
            return []
        }
        return [StyleViolation(ruleDescription: self.dynamicType.description,
            severity: configuration.severity,
            location: Location(file: file.path, line: max(file.lines.count, 1)))]
    }

    public func correctFile(file: File) -> [Correction] {
        guard let count = file.contents.trailingNewlineCount() where count != 1 else {
            return []
        }
        let region = file.regions().filter {
            $0.contains(Location(file: file.path, line: max(file.lines.count, 1)))
        }.first
        if region?.isRuleDisabled(self) == true {
            return []
        }
        if count < 1 {
            file.append("\n")
        } else {
            file.write(file.contents.substringToIndex(file.contents.endIndex.advancedBy(1 - count)))
        }
        let location = Location(file: file.path, line: max(file.lines.count, 1))
        return [Correction(ruleDescription: self.dynamicType.description, location: location)]
    }
}
