//
//  ProtocolPropertyAccessorsOrderRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 15/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ProtocolPropertyAccessorsOrderRule: ConfigurationProviderRule, CorrectableRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "protocol_property_accessors_order",
        name: "Protocol Property Accessors Order",
        description: "When declaring properties in protocols, the order of accessors should be `get set`.",
        nonTriggeringExamples: [
            "protocol Foo {\n var bar: String { get set }\n }",
            "protocol Foo {\n var bar: String { get }\n }",
            "protocol Foo {\n var bar: String { set }\n }"
        ],
        triggeringExamples: [
            "protocol Foo {\n var bar: String { ↓set get }\n }"
        ],
        corrections: [
            "protocol Foo {\n var bar: String { ↓set get }\n }":
                "protocol Foo {\n var bar: String { get set }\n }"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(file: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(file: File) -> [NSRange] {
        return file.match(pattern: "\\bset\\s*get\\b", with: [.keyword, .keyword])
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(file: file), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .replacingCharacters(in: indexRange, with: "get set")
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
