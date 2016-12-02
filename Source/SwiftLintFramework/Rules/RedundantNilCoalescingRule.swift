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
        return matchPattern(
            "\\?\\?\\s*nil\\b", // ?? {whitespace} nil {word boundary}
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds()
        )
    }
}

public struct RedundantNilCoalescingRule: OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_nil_coalescing",
        name: "Redundant Nil Coalescing",
        description: "nil coalescing operator is only evaluated if the lhs is nil " +
            ", coalescing operator with nil as rhs is redundant",
        nonTriggeringExamples: [
            "var myVar: Int?; myVar ?? 0"
        ],
        triggeringExamples: [
            "var myVar = nil; myVar ↓?? nil"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        return file.violatingRedundantNilCoalescingRanges().map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

}
