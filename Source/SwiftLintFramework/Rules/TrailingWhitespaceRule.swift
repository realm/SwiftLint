//
//  TrailingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

struct TrailingWhitespaceRule: Rule {
    static let identifier = "trailing_whitespace"
    static let parameters = [RuleParameter<Void>]()

    static func validateFile(file: File) -> [StyleViolation] {
        return file.contents.lines().map { line in
            (
                index: line.index,
                trailingWhitespaceCount: line.content.countOfTailingCharactersInSet(
                    NSCharacterSet.whitespaceCharacterSet()
                )
            )
        }.filter {
            $0.trailingWhitespaceCount > 0
        }.map {
            StyleViolation(type: .TrailingWhitespace,
                location: Location(file: file.path, line: $0.index),
                severity: .Medium,
                reason: "Line #\($0.index) should have no trailing whitespace: " +
                "current has \($0.trailingWhitespaceCount) trailing whitespace characters")
        }
    }
}
