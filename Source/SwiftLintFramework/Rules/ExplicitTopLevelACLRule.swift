//
//  ExplicitTopLevelACLRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 4/28/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExplicitTopLevelACLRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_top_level_acl",
        name: "Explicit Top Level ACL",
        description: "Top-level declarations should specify Access Control Level keywords explicitly.",
        nonTriggeringExamples: [
            "internal enum A {}\n",
            "public final class B {}\n",
            "private struct C {}\n",
            "internal enum A {\n enum B {}\n}",
            "internal final class Foo {}",
            "internal\nclass Foo {}",
            "internal func a() {}\n"
        ],
        triggeringExamples: [
            "enum A {}\n",
            "final class B {}\n",
            "struct C {}\n",
            "func a() {}\n",
            "internal let a = 0\nfunc b() {}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        // find all top-level types marked as internal (either explictly or implictly)
        let internalTypesOffsets = file.structure.dictionary.substructure.flatMap { element -> Int? in
            if element.accessibility.flatMap(AccessControlLevel.init(identifier:)) == .internal {
                return element.offset
            }

            return nil
        }

        guard !internalTypesOffsets.isEmpty else {
            return []
        }

        // find all "internal" tokens
        let contents = file.contents.bridge()
        let allInternalRanges = file.match(pattern: "internal", with: [.attributeBuiltin]).flatMap {
            contents.NSRangeToByteRange(start: $0.location, length: $0.length)
        }

        let violationOffsets = internalTypesOffsets.filter { typeOffset in
            // find the last "internal" token before the type
            guard let previousInternalByteRange = lastInternalByteRange(before: typeOffset,
                                                                        in: allInternalRanges) else {
                // didn't find a candidate token, so we are sure it's a violation
                return true
            }

            // the "internal" token correspond to the type if there're only
            // attributeBuiltin (`final` for example) tokens between them
            let length = typeOffset - previousInternalByteRange.location
            let range = NSRange(location: previousInternalByteRange.location, length: length)
            let internalDoesntBelongToType = Set(file.syntaxMap.kinds(inByteRange: range)) != [.attributeBuiltin]

            return internalDoesntBelongToType
        }

        return violationOffsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func lastInternalByteRange(before typeOffset: Int, in ranges: [NSRange]) -> NSRange? {
        let firstPartition = ranges.partitioned(by: { $0.location > typeOffset }).first
        return firstPartition.last
    }
}
