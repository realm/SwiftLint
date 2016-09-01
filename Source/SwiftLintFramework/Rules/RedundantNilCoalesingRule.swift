//
//  RedundantNilCoalesingRule.swift
//  SwiftLint
//
//  Created by Daniel Beard on 8/24/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension File {
    private func violatingRedundantNilCoalesingRanges() -> [NSRange] {
        return matchPattern(
            "\\?\\?\\s*nil\\b", // ?? {whitespace} nil {word boundary}
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds()
        )
    }
}

public struct RedundantNilCoalesingRule: OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_nil_coalesing",
        name: "Redundant Nil Coalesing",
        description: "nil coalescing operator is only evaluated if the lhs is nil " +
            ", coalesing operator with nil as rhs is redundant",
        nonTriggeringExamples: [
            "var myVar: Int?; myVar ?? 0"
        ],
        triggeringExamples: [
            "var myVar = nil; myVar ↓?? nil"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.violatingRedundantNilCoalesingRanges().map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

}
