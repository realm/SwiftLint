//
//  TrailingNewlineRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension String {
    private func countOfTrailingCharacters(in characterSet: CharacterSet) -> Int {
        var count = 0
        for char in unicodeScalars.lazy.reversed() {
            if !characterSet.contains(char) {
                break
            }
            count += 1
        }
        return count
    }

    fileprivate func trailingNewlineCount() -> Int? {
        return countOfTrailingCharacters(in: .newlines)
    }
}

public struct TrailingNewlineRule: CorrectableRule, ConfigurationProviderRule, SourceKitFreeRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_newline",
        name: "Trailing Newline",
        description: "Files should have a single trailing newline.",
        kind: .style,
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

    public func validate(file: File) -> [StyleViolation] {
        if file.contents.trailingNewlineCount() == 1 {
            return []
        }
        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file.path, line: max(file.lines.count, 1)))]
    }

    public func correct(file: File) -> [Correction] {
        guard let count = file.contents.trailingNewlineCount(), count != 1 else {
            return []
        }
        guard let lastLineRange = file.lines.last?.range else {
            return []
        }
        if file.ruleEnabled(violatingRanges: [lastLineRange], for: self).isEmpty {
            return []
        }
        if count < 1 {
            file.append("\n")
        } else {
            let index = file.contents.index(file.contents.endIndex, offsetBy: 1 - count)
            file.write(file.contents[..<index])
        }
        let location = Location(file: file.path, line: max(file.lines.count, 1))
        return [Correction(ruleDescription: type(of: self).description, location: location)]
    }
}
