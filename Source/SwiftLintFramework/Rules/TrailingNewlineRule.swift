//
//  TrailingNewlineRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

extension String {
    private func trailingNewlineCount() -> Int? {
        let start = endIndex.advancedBy(-2, limit: startIndex)
        let range = Range(start: start, end: endIndex)
        let substring = self[range].utf16
        let newLineSet = NSCharacterSet.newlineCharacterSet()
        let slices = substring.split(allowEmptySlices: true) { !newLineSet.characterIsMember($0) }

        return slices.last?.count
    }
}

public struct TrailingNewlineRule: CorrectableRule {
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
            "let a = 0\n\n": "let a = 0\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        if file.contents.trailingNewlineCount() == 1 {
            return []
        }
        return [StyleViolation(ruleDescription: self.dynamicType.description,
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
