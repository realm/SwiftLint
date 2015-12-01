//
//  TrailingSemiColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-17.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

extension File {
    private func violatingTrailingSemicolonRanges() -> [NSRange] {
        return matchPattern(";$", excludingSyntaxKinds: SyntaxKind.commentAndStringKinds())
    }
}

public struct TrailingSemicolonRule: CorrectableRule {
    public static let description = RuleDescription(
        identifier: "trailing_semicolon",
        name: "Trailing Semicolon",
        description: "Lines should not have trailing semicolons.",
        nonTriggeringExamples: [ "let a = 0\n" ],
        triggeringExamples: [
            "let a = 0;\n",
            "let a = 0;\nlet b = 1\n"
        ],
        corrections: [
            "let a = 0;\n": "let a = 0\n",
            "let a = 0;\nlet b = 1\n": "let a = 0\nlet b = 1\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.violatingTrailingSemicolonRanges().map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let fileRegions = file.regions()
        let violatingRanges = file.violatingTrailingSemicolonRanges().filter { range in
            let region = fileRegions.filter {
                $0.contains(Location(file: file, offset: range.location))
            }.first
            return region?.isRuleEnabled(self) ?? true
        }
        let adjustedRanges = violatingRanges.reduce([NSRange]()) { adjustedRanges, element in
            let adjustedLocation = element.location - adjustedRanges.count
            let adjustedRange = NSRange(location: adjustedLocation, length: element.length)
            return adjustedRanges + [adjustedRange]
        }
        if adjustedRanges.isEmpty {
            return []
        }
        var correctedContents = file.contents
        for range in adjustedRanges {
            if let indexRange = correctedContents.nsrangeToIndexRange(range) {
                correctedContents = correctedContents
                    .stringByReplacingCharactersInRange(indexRange, withString: "")
            }
        }
        file.write(correctedContents)
        return adjustedRanges.map {
            Correction(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: $0.location))
        }
    }
}
