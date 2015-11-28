//
//  TrailingWhitespaceRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct TrailingWhitespaceRule: CorrectableRule {
    public static let description = RuleDescription(
        identifier: "trailing_whitespace",
        name: "Trailing Whitespace",
        description: "Lines should not have trailing whitespace.",
        nonTriggeringExamples: [ "//\n" ],
        triggeringExamples: [ "// \n" ],
        corrections: [ "// \n": "//\n" ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.lines.filter {
            $0.content.hasTrailingWhitespace()
        }.map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file.path, line: $0.index))
        }
    }

    public func correctFile(file: File) {
        let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
        let correctedContents = file.lines.map {
            ($0.content as NSString).stringByTrimmingTrailingCharactersInSet(whitespaceCharacterSet)
        }.joinWithSeparator("\n") + "\n" // re-add trailing newline
        if correctedContents != file.contents {
            file.write(correctedContents)
        }
    }
}
