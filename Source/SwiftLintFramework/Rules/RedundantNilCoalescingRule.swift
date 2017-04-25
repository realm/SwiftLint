//
//  RedundantNilCoalescingRule.swift
//  SwiftLint
//
//  Created by Daniel Beard on 8/24/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension File {
    fileprivate func violatingRedundantNilCoalescingRanges() -> [NSRange] {
        // {whitespace} ?? {whitespace} nil {word boundary}
        return match(pattern: "\\s?\\?{2}\\s*nil\\b", with: [.keyword])
    }
}

public struct RedundantNilCoalescingRule: OptInRule, CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_nil_coalescing",
        name: "Redundant Nil Coalescing",
        description: "nil coalescing operator is only evaluated if the lhs is nil" +
            ", coalescing operator with nil as rhs is redundant",
        nonTriggeringExamples: [
            "var myVar: Int?; myVar ?? 0\n"
        ],
        triggeringExamples: [
            "var myVar: Int? = nil; myVar↓ ?? nil\n",
            "var myVar: Int? = nil; myVar↓??nil\n"
        ],
        corrections: [
            "var myVar: Int? = nil; let foo = myVar↓ ?? nil\n": "var myVar: Int? = nil; let foo = myVar\n",
            "var myVar: Int? = nil; let foo = myVar↓??nil\n": "var myVar: Int? = nil; let foo = myVar\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.violatingRedundantNilCoalescingRanges().map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingRedundantNilCoalescingRanges(), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .replacingCharacters(in: indexRange, with: "")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }
}
